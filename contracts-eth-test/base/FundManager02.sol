// SPDX-License-Identifier: GPL-2.0-or-later

/**
 *         ██╗    ██╗██╗██╗  ██╗██╗    ████████╗██████╗ ██╗   ██╗████████╗██╗  ██╗
 *         ██║    ██║██║██║ ██╔╝██║    ╚══██╔══╝██╔══██╗██║   ██║╚══██╔══╝██║  ██║
 *         ██║ █╗ ██║██║█████╔╝ ██║       ██║   ██████╔╝██║   ██║   ██║   ███████║
 *         ██║███╗██║██║██╔═██╗ ██║       ██║   ██╔══██╗██║   ██║   ██║   ██╔══██║
 *         ╚███╔███╔╝██║██║  ██╗██║       ██║   ██║  ██║╚██████╔╝   ██║   ██║  ██║
 *          ╚══╝╚══╝ ╚═╝╚═╝  ╚═╝╚═╝       ╚═╝   ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝
 *
 *  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
 *  ┃                        Website: https://wikitruth.eth.limo/                         ┃
 *  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
 */

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import {ITruthBox} from "@marketplace-v1/interfaces/ITruthBox.sol";
import {
    FundManagerEvents,
    FundsType,
    RewardType
} from "@marketplace-v1/interfaces-eth/IFundManager.sol";
import {IExchange} from "@marketplace-v1/interfaces-eth/IExchange.sol";

import {I_Swap} from "../dex/interfaceSwap.sol";

import {FundManager01} from "./FundManager01.sol";

/**
 * @title FundManager02
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager02 is FundManager01, FundManagerEvents {
    using SafeERC20 for IERC20;

    // ====================================================================================================================

    error EmptyList();
    // error InsufficientFundAmount();
    error WithdrawError();
    error ApprovalFailed();

    /// @dev Total reward amounts
    mapping(address token => uint256) internal _totalRewardAmounts;

    // Order amounts mapping (by token recorded by EXCHANGE contract, boxId and buyer address)
    mapping(uint256 boxId => mapping(address buyer => uint256))
        internal _orderAmounts;

    // Minter reward amounts for each token (only two types: token recorded by EXCHANGE contract, and settlement token)
    mapping(address minter => mapping(address token => uint256))
        internal _minterRewardAmounts;

    // User reward amounts (using settlement token)
    mapping(address helper => mapping(address token => uint256))
        internal _helperRewrdAmounts;

    // ====================================================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) FundManager01(addrManager_) ERC2771Context(trustedForwarder_) {}

    // ====================================================================================================================
    // Reward Allocation Functions

    /**
     * @dev Internal method: Calculate allocation
     * @param boxId_ TruthBox ID
     * @param amount_ Amount
     * @param token_ Token address
     */
    function _calculateAllocation(
        uint256 boxId_,
        address minter_,
        uint256 amount_,
        address token_
    ) private {
        // Get various rates and roles
        address completer = EXCHANGE.completerOf(boxId_);
        address seller = EXCHANGE.sellerOf(boxId_);
        uint8 sellerRate;
        uint8 completerRate;
        // Calculate rewards

        if (completer != address(0)) {
            completerRate = _helperRewardRate;
        }
        // If there is a seller, it means the token is the original token
        if (seller != address(0)) {
            sellerRate = _helperRewardRate;
        }

        uint8 totalRate = _serviceFeeRate + sellerRate + completerRate;

        address settlementToken = ADDR_MANAGER.settlementToken();

        uint256 amountIn_token = (amount_ * totalRate) / 1000;
        uint256 amountOut_settlementToken;

        if (token_ != settlementToken) {
            // totalRate += _extraFeeRate;
            (amountIn_token, amountOut_settlementToken) = _swap(
                boxId_,
                token_,
                settlementToken,
                amount_,
                totalRate
            );
        } else {
            // If token is settlement token, calculate allocation directly, and amountOut and amountIn are equal
            amountOut_settlementToken = amountIn_token;
        }

        unchecked {
            // Calculate allocation amounts
            uint256 sellerRewards = (amountOut_settlementToken * sellerRate) /
                totalRate;
            uint256 completerRewards = (amountOut_settlementToken *
                completerRate) / totalRate;

            if (completerRewards > 0) {
                _helperRewrdAmounts[completer][
                    settlementToken
                ] += completerRewards;
                emit RewardsAdded(
                    boxId_,
                    settlementToken,
                    completerRewards,
                    RewardType.Completer
                );
            }
            // If there is a seller, it means the token is the original token
            if (sellerRewards > 0) {
                _helperRewrdAmounts[seller][settlementToken] += sellerRewards;
                emit RewardsAdded(
                    boxId_,
                    settlementToken,
                    sellerRewards,
                    RewardType.Seller
                );
            }
            // Update minter rewards (using original token)
            _minterRewardAmounts[minter_][token_] += (amount_ - amountIn_token);
            emit RewardsAdded(
                boxId_,
                token_,
                (amount_ - amountIn_token),
                RewardType.Minter
            );

            // Directly assign the service fee to the DAO fund manager contract
            IERC20(settlementToken).safeTransfer(
                ADDR_MANAGER.daoFundManager(),
                (amountOut_settlementToken - sellerRewards - completerRewards)
            );

            // Record total reward amount
            _totalRewardAmounts[token_] += amount_;
            emit RewardsAdded(boxId_, token_, amount_, RewardType.Total);
        }
    }

    /**
     * @dev Calculate how much tokenIn is needed to swap and how much tokenOut can be swapped
     * @param boxId_ TruthBox ID
     * @param tokenIn_ Token address (the token to be swapped)
     * @param tokenOut_ Token address (the token to be swapped to)
     * @param amount_ Amount
     * @param totalRate_ Total rate
     * @return amountIn_ Amount of tokenIn_ needed to swap
     * @return amountOut_ Amount of tokenOut_ can be swapped
     */
    function _swap(
        uint256 boxId_,
        address tokenIn_,
        address tokenOut_,
        uint256 amount_,
        uint8 totalRate_
    ) private returns (uint256, uint256) {
        address[] memory swapContracts = ADDR_MANAGER.swapContracts();
        if (swapContracts.length == 0) revert EmptyList();

        // Authorize the maximum possible amount of tokens to SwapRouter
        if (
            IERC20(tokenIn_).allowance(address(this), swapContracts[0]) <
            amount_
        ) {
            _approveToken(tokenIn_, swapContracts[0]);
        }
        /**
         * @dev Calculate how much tokenOut can be swapped with amountIn
         */
        uint256 amountOut = I_Swap(swapContracts[0]).getSwapAmountOut(
            tokenIn_,
            tokenOut_,
            amount_
        );
        // Reset the price of TruthBox
        TRUTH_BOX.setPrice(boxId_, amountOut);

        // Calculate the amount of funds used to allocate to other roles
        // Include service fee, seller fee, completer fee
        amountOut = (amountOut * totalRate_) / 1000;

        // Calculate the amount of funds used to swap
        uint256 amountIn = I_Swap(swapContracts[0]).swapForExact(
            tokenIn_,
            tokenOut_,
            amountOut
        );

        return (amountIn, amountOut);
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
     * @param list_ List of TruthBox IDs
     * @param type_ Type of withdrawal, either 0(order) or 1(refund)
     */
    function _withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_,
        FundsType type_
    ) internal nonReentrant whenNotPaused {
        if (list_.length == 0) revert EmptyList();
        uint256 amount;
        IExchange exchange = EXCHANGE;
        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();

        // Process refunds for each box
        for (uint256 i = 0; i < list_.length; i++) {
            uint256 boxId = list_[i];
            uint256 orderAmount = _orderAmounts[boxId][sender];
            address buyer = exchange.buyerOf(boxId);
            if (orderAmount == 0) {
                revert AmountIsZero();
            }

            if (type_ == FundsType.Order) {
                // Cannot be the current buyer
                if (sender == buyer) revert InvalidCaller();
            } else if (type_ == FundsType.Refund) {
                // The caller must be the buyer and the refund must be permitted
                if (sender != buyer || !exchange.refundPermit(boxId)) {
                    revert WithdrawError();
                }
                exchange.setRefundPermit(boxId, false);
            }

            // Confirm token type matches
            if (exchange.acceptedToken(boxId) != token_) {
                revert WithdrawError();
            }
            unchecked {
                amount += orderAmount;
            }
            _orderAmounts[boxId][sender] = 0;
        }

        // Execute refund
        IERC20(token_).safeTransfer(sender, amount);

        uint256 userId = USER_MANAGER.getUserId(sender);
        emit OrderAmountWithdraw(list_, token_, userId, amount, type_);
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
