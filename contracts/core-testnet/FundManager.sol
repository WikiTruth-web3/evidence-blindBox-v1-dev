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
    FundsType,
    RewardType
} from "@marketplace-v1/interfaces/IFundManager.sol";
import {FundManager02} from "./base/FundManager02.sol";

/**
 * @title FundManager
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager is FundManager02 {
    using SafeERC20 for IERC20;
    // ====================================================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) FundManager02(addrManager_, trustedForwarder_) {}

    // ====================================================================================================================

    /**
     * @dev Pay order amount
     * @param boxId_ TruthBox ID
     * @param buyer_ Buyer address
     * @param amount_ Amount to pay
     */
    function payOrderAmount(
        uint256 boxId_,
        address buyer_,
        uint256 amount_
    ) external onlyProjectContract {
        address token = EXCHANGE.acceptedToken(boxId_);

        IERC20(token).safeTransferFrom(buyer_, address(this), amount_);

        _orderAmounts[boxId_][buyer_] += amount_;

        uint256 userId = USER_MANAGER.getUserId(buyer_);
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

    // ====================================================================================================================
    // Withdrawal Functions
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
        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();
        uint256 amount = _helperRewrdAmounts[sender][token_];
        if (amount == 0) {
            revert AmountIsZero();
        }
        _helperRewrdAmounts[sender][token_] = 0;
        IERC20(token_).safeTransfer(sender, amount);

        uint256 userId = USER_MANAGER.getUserId(sender);
        emit HelperRewrdsWithdraw(userId, token_, amount);
    }

    /**
     * @dev Withdraw minter rewards
     * @param token_ Token address
     */
    function withdrawMinterRewards(
        address token_
    ) external nonReentrant whenNotPaused {
        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();
        uint256 amount = _minterRewardAmounts[sender][token_];
        if (amount == 0) {
            revert AmountIsZero();
        }
        // Zero out reward amount
        _minterRewardAmounts[sender][token_] = 0;
        // Execute safeTransfer
        IERC20(token_).safeTransfer(sender, amount);

        uint256 userId = USER_MANAGER.getUserId(sender);
        emit MinterRewardsWithdraw(userId, token_, amount);
    }
}
