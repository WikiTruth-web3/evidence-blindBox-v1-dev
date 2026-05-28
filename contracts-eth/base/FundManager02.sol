// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";
import {
    FundManagerEvents,
    FundsType
} from "@interfaces/eth/IFundManager.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";

// import {I_Swap} from "../dex/interfaceSwap.sol";

import {FundManager01} from "./FundManager01.sol";

/**
 * @title FundManager02
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager02 is FundManager01, FundManagerEvents {
    using SafeERC20 for IERC20;
    address internal DAO_FUND_MANAGER;

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

    constructor(address addrManager_) FundManager01(addrManager_) {}

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
        bytes32 minterId = BLIND_BOX.minterIdOf(boxId_);

        uint256 serviceFee = (amount_ * _serviceFeeRate) / 1000; // accepted token

        unchecked {
            // Update minter rewards (using original token)
            _rewardAmounts[minterId][token_] += (amount_ - serviceFee );
            emit RewardsAdded(
                boxId_,
                token_,
                (amount_ - serviceFee )
            );

            // Directly assign the service fee to the DAO fund manager contract
            IERC20(token_).safeTransfer(
                DAO_FUND_MANAGER,
                (serviceFee )
            );

            // Record total reward amount
            _totalRewardAmounts[token_] += amount_;
        }
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
     * @param virtual_ user virtual address(privacy erc20)
     * @param type_ Type of withdrawal, order or refund
     */
    function _withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_,
        address virtual_,
        FundsType type_
    ) internal nonReentrant whenNotPaused {
        if (list_.length == 0) revert EmptyList();
        uint256 amount;
        IExchange exchange = EXCHANGE;
        // erc2771 - msg.sender is the real caller
        address sender = msg.sender;
        bytes32 userId = USER_MANAGER.getUserId(sender);

        // Process refunds for each box
        for (uint256 i = 0; i < list_.length; i++) {
            uint256 boxId = list_[i];
            uint256 orderAmount = _orderAmounts[boxId][userId];
            bytes32 buyerId = exchange.buyerIdOf(boxId);
            if (orderAmount == 0) {
                revert AmountIsZero();
            }

            if (type_ == FundsType.Order) {
                // Cannot be the current buyer
                if (userId == buyerId) revert InvalidCaller();
            } else if (type_ == FundsType.Refund) {
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
        IERC20(token_).safeTransfer(virtual_, amount);

        if (type_ == FundsType.Order) {
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
