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
// import {Pausable} from "../openzeppelin/contracts/utils/Pausable.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITruthBox} from "@marketplace-v1/interfaces/ITruthBox.sol";
import {IFundManager} from "@marketplace-v1/interfaces/IFundManager.sol";
import {IExchange} from "@marketplace-v1/interfaces-eth/IExchange.sol";
import {I_Swap} from "./dex/interfaceSwap.sol";

import {FundManagerBase} from "./base/FundManagerBase.sol";

/**
 * @title FundManager
 * @dev Fund management contract that supports multiple tokens
 * v1.6 upgraded version of FundManager, extending existing FundManager to support multi-token transactions
 */

contract FundManager is FundManagerBase, IFundManager {
    using SafeERC20 for IERC20;

    // ====================================================================================================================

    error EmptyList();
    error WithdrawError();
    error ApprovalFailed();

    // =======================================================================================

    /// @dev Total reward amounts
    mapping(address token => uint256) internal _totalRewardAmounts;

    // Order amounts mapping (by token recorded by EXCHANGE contract, boxId and buyer address)
    mapping(uint256 boxId => mapping(address buyer => uint256))
        private _orderAmounts;

    // Minter reward amounts for each token (only two types: token recorded by EXCHANGE contract, and settlement token)
    mapping(address minter => mapping(address token => uint256))
        private _minterRewardAmounts;

    // User reward amounts (using settlement token)
    mapping(address helper => mapping(address token => uint256))
        private _helperRewrdAmounts;

    // ====================================================================================================================

    constructor(address addrManager_) FundManagerBase(addrManager_) {}

    function setAddress() external checkSetCaller {
        _setAddress();
    }

    // ====================================================================================================================
    // Fund Pay Functions
    function _approveToken(address token, address spender) private {
        // Authorize the maximum possible amount of tokens, effectively an "unlimited" authorization
        bool success = IERC20(token).approve(spender, type(uint256).max);
        if (!success) revert ApprovalFailed();
    }

    /**
     * @dev Pay order amount
     * @param boxId_ TruthBox ID
     * @param buyer_ Buyer address
     * @param amount_ Amount to deposit
     */
    function payOrderAmount(
        uint256 boxId_,
        address buyer_,
        uint256 amount_
    ) external onlyProjectContract {
        address token = EXCHANGE.acceptedToken(boxId_);

        IERC20(token).safeTransferFrom(buyer_, address(this), amount_);

        _orderAmounts[boxId_][buyer_] += amount_;

        uint256 userId = USER_ID.getUserId(buyer_);
        emit OrderAmountPaid(boxId_, userId, token, amount_);
    }

    /**
     * @dev Pay delay fee
     * @param boxId_ TruthBox ID
     * @param sender_ Sender address
     * @param amount_ Amount to pay
     */
    function payDelayFee(
        uint256 boxId_,
        address sender_,
        uint256 amount_
    ) external onlyProjectContract {
        address settlementToken = ADDR_MANAGER.settlementToken();
        IERC20(settlementToken).transferFrom(sender_, address(this), amount_);

        address minter = TRUTH_BOX.minterOf(boxId_);
        _calculateAllocation(boxId_, minter, amount_, settlementToken);
    }

    // ====================================================================================================================
    // Reward Allocation Functions

    /**
     * @dev Allocate rewards
     * @param boxId_ TruthBox ID
     */
    function allocationRewards(uint256 boxId_) external onlyProjectContract {
        address buyer = EXCHANGE.buyerOf(boxId_);
        address minter = TRUTH_BOX.minterOf(boxId_);
        address token = EXCHANGE.acceptedToken(boxId_);

        uint256 amount = _orderAmounts[boxId_][buyer];
        if (amount == 0) revert AmountIsZero();

        // Clear the original token order amount
        _orderAmounts[boxId_][buyer] = 0;
        _calculateAllocation(boxId_, minter, amount, token);
    }

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
    ) private nonReentrant whenNotPaused {
        if (list_.length == 0) revert EmptyList();
        uint256 amount;
        IExchange exchange = EXCHANGE;
        // Process refunds for each box
        for (uint256 i = 0; i < list_.length; i++) {
            uint256 boxId = list_[i];
            uint256 orderAmount = _orderAmounts[boxId][msg.sender];
            address buyer = exchange.buyerOf(boxId);
            if (orderAmount == 0) {
                revert AmountIsZero();
            }

            if (type_ == FundsType.Order) {
                // Cannot be the current buyer
                if (msg.sender == buyer) revert InvalidCaller();
            } else if (type_ == FundsType.Refund) {
                // The caller must be the buyer and the refund must be permitted
                if (msg.sender != buyer || !exchange.refundPermit(boxId)) {
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
            _orderAmounts[boxId][msg.sender] = 0;
        }

        // Execute refund
        IERC20(token_).safeTransfer(msg.sender, amount);

        uint256 userId = USER_ID.getUserId(msg.sender);
        emit OrderAmountWithdraw(list_, token_, userId, amount, type_);
    }

    /**
     * @dev Withdraw order amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of TruthBox IDs
     */
    function withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_
    ) external {
        _withdrawOrderAmounts(token_, list_, FundsType.Order);
    }

    /**
     * @dev Withdraw refund amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of TruthBox IDs
     */
    function withdrawRefundAmounts(
        address token_,
        uint256[] calldata list_
    ) external {
        _withdrawOrderAmounts(token_, list_, FundsType.Refund);
    }

    //--------------------------------------------------

    /**
     * @dev Withdraw other reward amounts (settlement token only)
     * @param token_ Token address
     */
    function withdrawHelperRewards(
        address token_
    ) external nonReentrant whenNotPaused {
        uint256 amount = _helperRewrdAmounts[msg.sender][token_];
        if (amount == 0) {
            revert AmountIsZero();
        }
        _helperRewrdAmounts[msg.sender][token_] = 0;
        IERC20(token_).safeTransfer(msg.sender, amount);

        uint256 userId = USER_ID.getUserId(msg.sender);
        emit HelperRewrdsWithdraw(userId, token_, amount);
    }

    /**
     * @dev Withdraw minter rewards
     * @param token_ Token address
     */
    function withdrawMinterRewards(
        address token_
    ) external nonReentrant whenNotPaused {
        uint256 amount = _minterRewardAmounts[msg.sender][token_];
        if (amount == 0) {
            revert AmountIsZero();
        }
        // Zero out reward amount
        _minterRewardAmounts[msg.sender][token_] = 0;
        // Execute safeTransfer
        IERC20(token_).safeTransfer(msg.sender, amount);

        uint256 userId = USER_ID.getUserId(msg.sender);
        emit MinterRewardsWithdraw(userId, token_, amount);
    }

    // ====================================================================================================================
    //                    Query Functions
    // ====================================================================================================================

    /**
     * @dev Get total reward amount
     * @param token_ Token address
     * @return Total reward amount
     */
    function totalRewardAmounts(address token_) public view returns (uint256) {
        return _totalRewardAmounts[token_];
    }

    // ----------------------------------------------------------------
    //                      Debugging Functions
    // ----------------------------------------------------------------

    /**
     * @dev Get order amount
     * @param boxId_ TruthBox ID
     * @param user_ User address
     * @return Order amount
     */
    function orderAmounts(
        uint256 boxId_,
        address user_
    ) external view returns (uint256) {
        return _orderAmounts[boxId_][user_];
    }

    /**
     * @dev Get helper reward amount
     * @param token_ Token address
     * @param helper_ Helper address
     * @return Helper reward amount
     */
    function helperRewardAmounts(
        address token_,
        address helper_
    ) external view returns (uint256) {
        // if (msg.sender != address(EXCHANGE)) revert InvalidCaller();
        return _helperRewrdAmounts[helper_][token_];
    }

    /**
     * @dev Get minter reward amount
     * @param token_ Token address
     * @param minter_ Minter address
     * @return Minter reward amount
     */
    function minterRewardAmounts(
        address token_,
        address minter_
    ) external view returns (uint256) {
        return _minterRewardAmounts[minter_][token_];
    }

    // --------------------------------------------------
}
