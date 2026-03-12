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
import {FundManager02} from "./FundManager02.sol";

/**
 * @title FundManager03
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager03 is FundManager02 {
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
    function _payOrderAmount(
        uint256 boxId_,
        address buyer_,
        uint256 amount_,
        bytes32 userId_
    ) internal {
        address token = EXCHANGE.acceptedToken(boxId_);

        IERC20(token).safeTransferFrom(buyer_, address(this), amount_);
        _orderAmounts[boxId_][userId_] += amount_;

        emit OrderAmountPaid(boxId_, userId_, token, amount_);
    }

    /**
     * @dev Pay delay fee
     * @param boxId_ TruthBox ID
     * @param sender_ Sender address
     * @param amount_ Amount to pay
     */
    function _payDelayFee(
        uint256 boxId_,
        address sender_,
        uint256 amount_
    ) internal {
        address settlementToken = ADDR_MANAGER.settlementToken();
        IERC20(settlementToken).safeTransferFrom(
            sender_,
            address(this),
            amount_
        );

        bytes32 minterId = TRUTH_BOX.minterIdOf(boxId_);
        _calculateAllocation(boxId_, minterId, amount_, settlementToken);
    }

    // ====================================================================================================================
    // Reward Allocation Functions

    /**
     * @dev Allocate rewards
     * @param boxId_ TruthBox ID
     */
    function _allocationRewards(uint256 boxId_) internal {
        bytes32 buyerId = EXCHANGE.buyerIdOf(boxId_);
        bytes32 minterId = TRUTH_BOX.minterIdOf(boxId_);
        address token = EXCHANGE.acceptedToken(boxId_);

        uint256 amount = _orderAmounts[boxId_][buyerId];
        if (amount == 0) revert AmountIsZero();

        // Clear the original token order amount
        _orderAmounts[boxId_][buyerId] = 0;
        _calculateAllocation(boxId_, minterId, amount, token);
    }

    // ====================================================================================================================
    /**
     * @dev Withdraw other reward amounts (settlement token only)
     * @param token_ Token address
     */
    function _withdrawRewards(
        address token_
    ) internal nonReentrant whenNotPaused {
        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();
        bytes32 userId = USER_MANAGER.getUserId(sender);
        uint256 amount = _rewardAmounts[userId][token_];
        if (amount == 0) {
            revert AmountIsZero();
        }
        _rewardAmounts[userId][token_] = 0;
        IERC20(token_).safeTransfer(sender, amount);

        emit RewardsWithdraw(userId, token_, amount);
    }
}
