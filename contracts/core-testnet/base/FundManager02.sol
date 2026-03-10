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
import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// import {ITruthBox} from "@marketplace-v1/interfaces/ITruthBox.sol";
import {
    FundManagerEvents,
    FundsType,
    RewardType
} from "@marketplace-v1/interfaces/IFundManager.sol";
import {IExchange} from "@marketplace-v1/interfaces/IExchange.sol";
import {SiweContext} from "@siwe/SiweContext.sol";

import {ISwapRouter} from "@uniswap-v3/interfaces/ISwapRouter.sol";
import {IQuoter} from "@uniswap-v3/interfaces/IQuoter.sol";

import {FundManager01} from "./FundManager01.sol";

/**
 * @title FundManager02
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager02 is
    FundManager01,
    FundManagerEvents,
    ERC2771Context,
    SiweContext
{
    using SafeERC20 for IERC20;

    // ====================================================================================================================

    /// @dev Total reward amounts
    mapping(address token => uint256) internal _totalRewardAmounts;

    // Order amounts mapping (by token recorded by EXCHANGE contract, boxId and buyer userId)
    mapping(uint256 boxId => mapping(uint256 userId => uint256))
        internal _orderAmounts;

    // Minter reward amounts for each token (only two types: token recorded by EXCHANGE contract, and settlement token)
    mapping(uint256 userId => mapping(address token => uint256))
        internal _rewardAmounts;

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
     * @param minterId_ Minter userId
     * @param amount_ Amount
     * @param token_ Token address
     */
    function _calculateAllocation(
        uint256 boxId_,
        uint256 minterId_,
        uint256 amount_,
        address token_
    ) internal {
        // Get various rates and roles
        uint256 completerId = EXCHANGE.completerIdOf(boxId_);
        uint256 sellerId = EXCHANGE.sellerIdOf(boxId_);
        uint8 sellerRate;
        uint8 completerRate;
        // Calculate rewards

        if (completerId != 0) {
            completerRate = _helperRewardRate;
        }
        // If there is a seller, it means the token is the original token
        if (sellerId != 0) {
            sellerRate = _helperRewardRate;
        }

        uint8 totalRate = _serviceFeeRate + sellerRate + completerRate;

        address settlementToken = ADDR_MANAGER.settlementToken();

        uint256 amountIn; // accepted token
        uint256 amountOut; // settlement token

        if (token_ != settlementToken) {
            // Add extra fee rate to total rate
            totalRate += _extraFeeRate;
            // If token is not settlement token, it needs to be swapped
            (amountIn, amountOut) = _swap(
                boxId_,
                token_,
                settlementToken,
                amount_,
                totalRate
            );
        } else {
            // If token is settlement token, calculate allocation directly, and amountOut and amountIn are equal
            amountIn = (amount_ * totalRate) / 1000;
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

            // Assign service fee to DAO fund manager
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
        // address swapContract = swapContracts[0];
        // address quoter = swapContracts[1];

        // check allowance and approve
        if (
            IERC20(tokenIn_).allowance(address(this), swapContracts[0]) <
            amount_
        ) {
            _approveToken(tokenIn_, swapContracts[0]);
        }

        // step 1: calculate the amount of tokenOut that can be exchanged for tokenIn
        // using quoter to calculate the amount of tokenOut that can be exchanged for tokenIn
        uint256 totalAmountOut = IQuoter(swapContracts[1])
            .quoteExactInputSingle(
                tokenIn_,
                tokenOut_,
                3000, // 0.3% service fee
                amount_, // using the exact amount of tokenIn
                0 // no price limit
            );

        // step 2: calculate the amount of tokenOut that can be exchanged for tokenIn
        uint256 amountOut_ = (totalAmountOut * totalRate_) / 1000;

        // step 3: execute the swap, using exactOutputSingle to exchange the exact amount of tokenOut
        uint256 amountIn_ = ISwapRouter(swapContracts[0]).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenIn_,
                tokenOut: tokenOut_,
                fee: 3000, // 0.3% service fee
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountOut: amountOut_, // exact amount of tokenOut
                amountInMaximum: amount_,
                sqrtPriceLimitX96: 0
            })
        );

        // step 4: reset the price of TruthBox
        // Because the delay fee must be in the settlementToken,
        // so we need to reset the price of TruthBox
        TRUTH_BOX.setPrice(boxId_, totalAmountOut);

        return (amountIn_, amountOut_);
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
        uint256 userId = USER_MANAGER.viewUserId(sender);

        // Process refunds for each box
        for (uint256 i = 0; i < list_.length; i++) {
            uint256 boxId = list_[i];
            uint256 orderAmount = _orderAmounts[boxId][userId];
            uint256 buyerId = exchange.buyerIdOf(boxId);
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
    //                                       View function
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
