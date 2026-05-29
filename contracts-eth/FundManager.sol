// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Main} from "@interfaces/IContracts.sol";

import {IFundManager,FundsType} from "@interfaces/eth/IFundManager.sol";
import {FundManager03} from "./base/FundManager03.sol";
/**
 * @title FundManager
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager is FundManager03, IFundManager {
    using SafeERC20 for IERC20;
    // ====================================================================================================================

    constructor(address addrManager_, address trustForwarder_) FundManager03(addrManager_, trustForwarder_) {}

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setContracts() external onlyManager {
        _setContracts(Main.FundManager);
    }

    // ====================================================================================================================

    /**
     * @dev Pay order amount
     * @param boxId_ BlindBox ID
     * @param buyer_ Buyer address
     * @param amount_ Amount to pay
     * @param userId_ Buyer id
     */
    function payOrderAmount(
        uint256 boxId_,
        address buyer_,
        uint256 amount_,
        bytes32 userId_
    ) external onlyProjectContract {
        _payOrderAmount(boxId_, buyer_, amount_, userId_);
    }

    /**
     * @dev Pay delay fee
     * @param boxId_ BlindBox ID
     * @param sender_ Sender address
     * @param amount_ Amount to pay
     */
    function payDelayFee(
        uint256 boxId_,
        address sender_,
        uint256 amount_
    ) external onlyProjectContract {
        _payDelayFee(boxId_, sender_, amount_);
    }

    // ====================================================================================================================
    // Reward Allocation Functions

    /**
     * @dev Allocate rewards
     * @param boxId_ BlindBox ID
     */
    function allocationRewards(uint256 boxId_) external onlyProjectContract {
        _allocationRewards(boxId_);
    }

    // ====================================================================================================================
    // Withdrawal Functions
    /**
     * @dev Withdraw order amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of BlindBox IDs
     * @param receiver_ user virtual address(privacy erc20)
     */
    function withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_,
        address receiver_
    ) external {
        _withdrawOrderAmounts(token_, list_, receiver_, FundsType.Order);
    }

    /**
     * @dev Withdraw refund amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of BlindBox IDs
     * @param receiver_ user virtual address(privacy erc20)
     */
    function withdrawRefundAmounts(
        address token_,
        uint256[] calldata list_,
        address receiver_
    ) external {
        _withdrawOrderAmounts(token_, list_, receiver_, FundsType.Refund);

    }

    //--------------------------------------------------

    /**
     * @dev Withdraw rewards
     * @param token_ Token address
     * @param receiver_ user virtual address(privacy erc20)
     */
    function withdrawRewards(address token_, address receiver_) external {
        _withdrawRewards(token_, receiver_);
    }

    // ====================================================================================================================
    //                    Query Functions
    // ====================================================================================================================

    /**
     * @dev Get order amount
     * @param boxId_ BlindBox ID
     * @param userId_ User ID
     * @return Order amount
     */
    function orderAmounts(
        uint256 boxId_,
        bytes32 userId_
    ) external view returns (uint256) {
        return _orderAmounts[boxId_][userId_];
    }

        /**
     * @dev Get reward amount
     * @param userId_ User ID
     * @param token_ BlindBox ID
     * @return Order amount
     */
    function rewardAmounts(
        bytes32 userId_,
        address token_
    ) external view returns (uint256) {
        return _rewardAmounts[userId_][token_];
    }

}
