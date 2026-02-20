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

import {IDaoFundManager} from "@wikitruth-v1/interfaces/IDaoFundManager.sol";

import {FundManagerBase} from "./abstract/FundManagerBase.sol";

/**
 * @title DaoFundManager
 * @notice Fund management contract that supports multiple tokens
 * Inherits IDaoFundManager interface to ensure consistency between interface and implementation
 */

contract DaoFundManager is FundManagerBase, IDaoFundManager {
    using SafeERC20 for IERC20;

    // ====================================================================================================================

    // error InsufficientFundAmount();
    error WithdrawError();
    error ApprovalFailed();

    /// @dev Total reward amounts
    uint256 internal _extendsFeeAmounts;

    // ====================================================================================================================

    constructor(address addrManager_) FundManagerBase(addrManager_) {}

    // ==========================================================================================================
    //                                          Override Functions
    // ==========================================================================================================

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external checkSetCaller {
        _setAddress();
    }

    // ====================================================================================================================

    /**
     * @dev Pay order amount
     * @param sender_ Sender address
     * @param amount_ Amount to pay
     */
    function receiveExtendsFee(
        address sender_,
        uint256 amount_
    ) external onlyProjectContract {
        address token = ADDR_MANAGER.officialToken();

        IERC20(token).safeTransferFrom(sender_, address(this), amount_);
        unchecked {
            _extendsFeeAmounts += amount_;
        }

        uint256 userId = USER_ID.getUserId(sender_);
        emit ExtendsFeePaid(userId, amount_);
    }

    function withdrawExtendsFee(
        address token_,
        uint256 amount_
    ) external onlyProjectContract {
        address token = ADDR_MANAGER.officialToken();

        IERC20(token).safeTransfer(msg.sender, amount_);

        unchecked {
            _extendsFeeAmounts -= amount_;
        }
    }
}
