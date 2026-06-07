// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";
import {
    FundManagerEvents,
    FundType
} from "@interfaces/IFundManager.sol";
import {IExchange} from "@interfaces/IExchange.sol";
import {IPriceOracle} from "../oracle/IPriceOracle.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


import {FundManager01} from "./FundManager01.sol";

/**
 * @title FundManager02
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager02 is FundManager01, FundManagerEvents, ERC2771Context {
    using SafeERC20 for IERC20;

    // ====================================================================================================================
    /// @dev Total reward amounts
    mapping(address token => uint256) internal _totalRewardAmounts;

    // Order amounts mapping (by token recorded by EXCHANGE contract, boxId and buyer address)
    mapping(uint256 boxId => mapping(bytes32 userId => uint256))
        internal _orderAmounts;

    // Minter reward amounts for each token (only two types: token recorded by EXCHANGE contract, and settlement token)
    mapping(bytes32 userId => mapping(address token => uint256))
        internal _rewardAmounts;

    // ====================================================================================================================

    constructor(address addrManager_, address trustForwarder_) FundManager01(addrManager_) ERC2771Context(trustForwarder_) {}

    // ====================================================================================================================
    // Reward Allocation Functions

    /**
     * @dev Internal method: Calculate allocation
     * @param boxId_ BlindBox ID
     * @param amount_ Amount
     * @param token_ Token address
     */
    function _calculateAllocation(
        uint256 boxId_,
        address token_,
        uint256 amount_
    ) internal {
        // Record total reward amount
        _totalRewardAmounts[token_] += amount_;

        bytes32 minterId = BLIND_BOX.minterIdOf(boxId_);
        bytes32 sellerId = EXCHANGE.sellerIdOf(boxId_);
        bytes32 completerId = EXCHANGE.completerIdOf(boxId_);

        uint256 toDaoTreasury = (amount_ * _serviceFeeRate) / 1000; // accepted token
        uint256 helperRewards = (amount_ * _helperFeeRate) / 1000; // accepted token
        uint256 helperRewards2 = helperRewards;

        address settlementToken = ADDR_MANAGER.settlementToken();
        amount_ -= toDaoTreasury;

        if (token_ != settlementToken) {
            helperRewards2 = _convertAmount( token_, settlementToken, helperRewards);
        } 

        unchecked {

            // If it is already the settlement token, no conversion needed
            if (sellerId != bytes32(0)) {
                _rewardAmounts[sellerId][settlementToken] += helperRewards2;
                amount_ -= helperRewards;
                if (token_ != settlementToken) {
                    toDaoTreasury += helperRewards;
                }
                emit RewardAdded(
                    boxId_,
                    sellerId,
                    settlementToken,
                    helperRewards2
                );
            }

            if (completerId != bytes32(0)) {
                _rewardAmounts[completerId][settlementToken] += helperRewards2;
                amount_ -= helperRewards;
                if (token_ != settlementToken) {
                    toDaoTreasury += helperRewards;
                }
                emit RewardAdded(
                    boxId_,
                    completerId,
                    settlementToken,
                    helperRewards2
                );
            }

            // Update minter rewards (using original token)
            _rewardAmounts[minterId][token_] += amount_;
            emit RewardAdded(
                boxId_,
                minterId,
                token_,
                amount_
            );

            // Send serviceFee (and helperRewards if converted) to DAO treasury
            IERC20(token_).safeTransfer(
                DAO_TREASURY,
                toDaoTreasury
            );
        }
    }

    function _convertAmount(address tokenIn_, address tokenOut_, uint256 amount_) internal view returns(uint256) {
        // If it is not the settlement token, use Oracle to convert helper rewards
        address oracleAddr = ADDR_MANAGER.getSpreadContract("PriceOracle");
        uint256 price = IPriceOracle(oracleAddr).getPrice(tokenIn_, tokenOut_);
        
        uint8 decimalsA = IERC20Metadata(tokenIn_).decimals();
        // uint8 decimalsB = IERC20Metadata(tokenOut_).decimals();
        return (amount_ * price * (10 ** 18)) / (1e18 * (10 ** decimalsA));
    }

    // Fund Deposit Functions
    function _approveToken(address token, address spender) internal {
        // Authorize the maximum possible amount of tokens, effectively an "unlimited" authorization
        bool success = IERC20(token).approve(spender, type(uint256).max);
        if (!success) revert ApprovalFailed();
    }

    // ====================================================================================================================
    // Withdrawal Functions
    /**
     * @dev Withdraw order amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of BlindBox IDs
     * @param receiver_ user virtual address(privacy erc20)
     * @param type_ Type of withdrawal, order or refund
     */
    function _withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_,
        address receiver_,
        FundType type_
    ) internal nonReentrant whenNotPaused {
        if (list_.length == 0) revert EmptyList();
        if (receiver_ == address(0)) revert ZeroAddress();
        uint256 amount;
        IExchange exchange = EXCHANGE;
        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();
        bytes32 userId = USER_MANAGER.getUserId(sender);

        // Process refunds for each box
        for (uint256 i = 0; i < list_.length; i++) {
            uint256 boxId = list_[i];
            uint256 orderAmount = _orderAmounts[boxId][userId];
            bytes32 buyerId = exchange.buyerIdOf(boxId);
            if (orderAmount == 0) {
                revert AmountIsZero();
            }

            if (type_ == FundType.Order) {
                // Cannot be the current buyer
                if (userId == buyerId) revert InvalidCaller();
            } else if (type_ == FundType.Refund) {
                // The caller must be the buyer and the refund must be permitted
                if (
                    userId != buyerId || 
                    !exchange.refundPermit(boxId)
                ) {
                    revert WithdrawError();
                }
            }

            // Confirm token type matches
            if (exchange.acceptedToken(boxId) != token_) {
                revert WithdrawError();
            }
            unchecked {
                amount += orderAmount;
            }
            _orderAmounts[boxId][userId] = 0;
        }

        // Execute refund
        IERC20(token_).safeTransfer(receiver_, amount);

        if (type_ == FundType.Order) {
            emit OrderAmountWithdraw(list_, token_, userId, amount);
        } else {
            emit RefundAmountWithdraw(list_, token_, userId, amount);
        }

    }
    // ===================================================================================

    /**
     * @dev Get total reward amount
     * @param token_ Token address
     * @return Total reward amount
     */
    function totalRewardAmounts(address token_) public view returns (uint256) {
        return _totalRewardAmounts[token_];
    }
}
