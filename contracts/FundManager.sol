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
} from "@marketplace-v1/interfaces/IFundManager.sol";
import {FundManager03} from "./base/FundManager03.sol";
/**
 * @title FundManager
 * @notice Fund management contract that supports multiple tokens
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager is FundManager03, IFundManager {
    using SafeERC20 for IERC20;
    // ====================================================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) FundManager03(addrManager_, trustedForwarder_) {}

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external onlyManager {
        _setAddress(CoreContracts.FundManager);
    }

    // ====================================================================================================================

    function payOrderAmount(
        uint256 boxId_,
        address buyer_,
        uint256 amount_,
        bytes32 userId_
    ) external onlyProjectContract {
        _payOrderAmount(boxId_, buyer_, amount_, userId_);
    }

    function payDelayFee(
        uint256 boxId_,
        address sender_,
        uint256 amount_
    ) external onlyProjectContract {
        _payDelayFee(boxId_, sender_, amount_);
    }

    // ====================================================================================================================

    function allocationRewards(uint256 boxId_) external onlyProjectContract {
        _allocationRewards(boxId_);
    }

    // ====================================================================================================================
    // Withdrawal Functions

    function withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_
    ) external {
        _withdrawOrderAmounts(token_, list_, FundsType.Order);
    }

    function withdrawRefundAmounts(
        address token_,
        uint256[] calldata list_
    ) external {
        _withdrawOrderAmounts(token_, list_, FundsType.Refund);
    }

    function withdrawRewards(address token_) external {
        _withdrawRewards(token_);
    }

    // ====================================================================================================================
    //                    Query Functions
    // ====================================================================================================================

    function restrictedGetOrderAmounts(
        uint256 boxId_,
        bytes32 userId_
    ) external view onlyProjectContract returns (uint256) {
        return _orderAmounts[boxId_][userId_];
    }

    function orderAmounts(
        uint256 boxId_,
        bytes memory siweToken_
    ) external view returns (uint256) {
        // Use SiweContext get sender
        address sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        bytes32 userId = USER_MANAGER.getUserId(sender);
        return _orderAmounts[boxId_][userId];
    }

    function rewardAmounts(
        address token_,
        bytes memory siweToken_
    ) external view returns (uint256) {
        // Use SiweContext get sender
        address sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        bytes32 userId = USER_MANAGER.getUserId(sender);
        return _rewardAmounts[userId][token_];
    }
}
