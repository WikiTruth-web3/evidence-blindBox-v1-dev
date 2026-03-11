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
     * @param boxId_ TruthBox ID
     * @param minterId_ Minter userId
     * @param amount_ Amount
     * @param token_ Token address
     */
    function _calculateAllocation(
        uint256 boxId_,
        bytes32 minterId_,
        uint256 amount_,
        address token_
    ) internal {
        // Get various rates and roles
        bytes32 completerId = EXCHANGE.completerIdOf(boxId_);
        bytes32 sellerId = EXCHANGE.sellerIdOf(boxId_);
        uint8 sellerRate;
        uint8 completerRate;
        // Calculate rewards

        if (completerId != bytes32(0)) {
            completerRate = _helperRewardRate;
        }
        // If there is a seller, it means the token is the original token
        if (sellerId != bytes32(0)) {
            sellerRate = _helperRewardRate;
        }

        uint8 totalRate = _serviceFeeRate + sellerRate + completerRate;

        address settlementToken = ADDR_MANAGER.settlementToken();

        uint256 amountIn = (amount_ * totalRate) / 1000; // accepted token
        uint256 amountOut; // settlement token

        if (token_ != settlementToken) {
            // totalRate += _extraFeeRate;
            (amountIn, amountOut) = _swap(
                boxId_,
                token_,
                settlementToken,
                amount_,
                totalRate
            );
        } else {
            // If token is settlement token, calculate allocation directly, and amountOut and amountIn are equal
            amountOut = amountIn;
        }

        unchecked {
            // Calculate allocation amounts
            uint256 sellerRewards = (amountOut * sellerRate) / totalRate;
            uint256 completerRewards = (amountOut * completerRate) / totalRate;

            if (completerRewards > 0) {
                _rewardAmounts[completerId][
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
                _rewardAmounts[sellerId][settlementToken] += sellerRewards;
                emit RewardsAdded(
                    boxId_,
                    settlementToken,
                    sellerRewards,
                    RewardType.Seller
                );
            }
            // Update minter rewards (using original token)
            _rewardAmounts[minterId_][token_] += (amount_ - amountIn);
            emit RewardsAdded(
                boxId_,
                token_,
                (amount_ - amountIn),
                RewardType.Minter
            );

            // Directly assign the service fee to the DAO fund manager contract
            IERC20(settlementToken).safeTransfer(
                ADDR_MANAGER.daoFundManager(),
                (amountOut - sellerRewards - completerRewards)
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
    ) internal returns (uint256, uint256) {
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
                if (userId != buyerId || !exchange.refundPermit(boxId)) {
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
            _orderAmounts[boxId][userId] = 0;
        }

        // Execute refund
        IERC20(token_).safeTransfer(sender, amount);

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
