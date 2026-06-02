// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FundType} from "@interfaces/IFundManager.sol";
import {FundManager02} from "./FundManager02.sol";

/**
 * @title FundManager03
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager03 is FundManager02 {
    using SafeERC20 for IERC20;
    // ====================================================================================================================

    constructor(address addrManager_, address trustForwarder_) FundManager02(addrManager_, trustForwarder_) {}

    // ====================================================================================================================

    /**
     * @dev Detect token type and return payment source address (virtual address for privacy tokens if authorized, else original)
     */
    function _getPayFrom(address token_, address from_) internal view returns (address) {
        (bool success, bytes memory data) = token_.staticcall(
            abi.encodeWithSignature("getVirtualAddress(address)", from_)
        );
        if (success && data.length == 32) {
            return abi.decode(data, (address));
        }
        return from_;
    }

    /**
     * @dev Pay order amount
     * @param boxId_ BlindBox ID
     * @param from_ Buyer address
     * @param amount_ Amount to pay
     * @param userId_ Buyer id
     */
    function _payOrderAmount(
        uint256 boxId_,
        address from_,
        uint256 amount_,
        bytes32 userId_
    ) internal {
        address token = EXCHANGE.acceptedToken(boxId_);

        address payFrom = _getPayFrom(token, from_);
        IERC20(token).safeTransferFrom(payFrom, address(this), amount_);

        _orderAmounts[boxId_][userId_] += amount_;

        emit OrderAmountPaid(boxId_, userId_, token, amount_);
    }

    /**
     * @dev Pay delay fee
     * @param boxId_ BlindBox ID
     * @param from_ Sender address
     * @param amount_ Amount to pay
     */
    function _payDelayFee(
        uint256 boxId_,
        address from_,
        uint256 amount_
    ) internal {
        address settlementToken = ADDR_MANAGER.settlementToken();
        address payFrom = _getPayFrom(settlementToken, from_);
        IERC20(settlementToken).safeTransferFrom(
            payFrom,
            address(this),
            amount_
        );

        _calculateAllocation(boxId_, settlementToken, amount_);
    }

    // ====================================================================================================================
    // Reward Allocation Functions

    /**
     * @dev Allocate rewards
     * @param boxId_ BlindBox ID
     */
    function _allocationRewards(uint256 boxId_) internal {
        bytes32 buyerId = EXCHANGE.buyerIdOf(boxId_);
        address token = EXCHANGE.acceptedToken(boxId_);

        uint256 amount = _orderAmounts[boxId_][buyerId];
        if (amount == 0) revert AmountIsZero();

        // Clear the original token order amount
        _orderAmounts[boxId_][buyerId] = 0;
        _calculateAllocation(boxId_, token, amount);
    }

    // ====================================================================================================================

    /**
     * @dev Withdraw rewards
     * @param token_ Token address
     * @param receiver_ user virtual address(privacy erc20)
     */
    function _withdrawRewards(
        address token_,
        address receiver_
    ) internal nonReentrant whenNotPaused {
        if(receiver_ == address(0)) revert ZeroAddress();
        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();
        bytes32 userId = USER_MANAGER.getUserId(sender);
        uint256 amount = _rewardAmounts[userId][token_];
        if (amount == 0) {
            revert AmountIsZero();
        }
        // Zero out reward amount
        _rewardAmounts[userId][token_] = 0;
        // Execute safeTransfer
        IERC20(token_).safeTransfer(receiver_, amount);

        emit RewardsWithdraw(userId, token_, amount);
    }
}
