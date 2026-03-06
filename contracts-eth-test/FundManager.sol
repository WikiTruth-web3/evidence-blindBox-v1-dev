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
import {CoreContracts} from "@marketplace-v1/interfaces/IContracts.sol";

import {
    IFundManager,
    FundsType,
    RewardType
} from "@marketplace-v1/interfaces-eth/IFundManager.sol";
import {FundManager03} from "./base/FundManager03.sol";
/**
 * @title FundManager
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager is FundManager03, IFundManager {
    using SafeERC20 for IERC20;
    // ====================================================================================================================

    constructor(address addrManager_) FundManager03(addrManager_) {}

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external onlyManager {
        _setAddress(CoreContracts.FundManager);
    }

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
    ) external {
        _payOrderAmount(boxId_, buyer_, amount_);
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
    ) external {
        _payDelayFee(boxId_, sender_, amount_);
    }

    // ====================================================================================================================
    // Reward Allocation Functions

    /**
     * @dev Allocate rewards
     * @param boxId_ TruthBox ID
     */
    function allocationRewards(uint256 boxId_) external {
        _allocationRewards(boxId_);
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
    function withdrawHelperRewards(address token_) external {
        _withdrawHelperRewards(token_);
    }

    /**
     * @dev Withdraw minter rewards
     * @param token_ Token address
     */
    function withdrawMinterRewards(address token_) external {
        _withdrawMinterRewards(token_);
    }

    // ====================================================================================================================
    //                    Query Functions
    // ====================================================================================================================

    /**
     * @dev Get order amount
     * @param boxId_ TruthBox ID
     * @param user_ User address
     * @return Order amount
     * This is the function for project contract to interact with,
     * so it needs to verify that msg.sender is the project contract!
     * Cannot be deleted!
     */
    // function orderAmounts(
    //     uint256 boxId_,
    //     address user_
    // ) external view onlyProjectContract returns (uint256) {
    //     return _orderAmounts[boxId_][user_];
    // }

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
     * @dev Get minter reward amount
     * @param token_ Token address
     * @return Minter reward amount
     */
    function minterRewardAmounts(
        address token_,
        address user_
    ) external view returns (uint256) {
        return _minterRewardAmounts[user_][token_];
    }

    /**
     * @dev Get helper reward amount
     * @param token_ Token address
     * @param user_ User address
     * @return Helper reward amount
     */
    function helperRewardAmounts(
        address token_,
        address user_
    ) external view returns (uint256) {
        return _helperRewrdAmounts[user_][token_];
    }
}
