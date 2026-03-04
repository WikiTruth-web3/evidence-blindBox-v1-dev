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

import {IUserManager} from "@marketplace-v1/interfaces-eth/IUserManager.sol";
import {IFundManager} from "@marketplace-v1/interfaces/IFundManager.sol";
import {IExchange} from "@marketplace-v1/interfaces-eth/IExchange.sol";
import {Error} from "@marketplace-v1/interfaces/interfaceError.sol";
import {
    IAddressManager
} from "@marketplace-v1/interfaces-eth/IAddressManager.sol";

import {Modifier} from "../modifier/Modifier.sol";
/**
 *  @notice TruthBoxBase
 *
 */

contract TruthBoxBase is Modifier {
    // address internal DAO;
    IUserManager internal USER_MANAGER;
    // ISiweAuth internal SIWE_AUTH;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;

    uint8 internal _incrementRate; // 2.0 * 100

    // ==================================================================================================
    uint256 internal _nextBoxId;

    // ==================================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
        _incrementRate = 200;
    }

    // ==========================================================================================================
    function _setAddress() internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        address exchange = addrMgr.exchange();
        address fundManager = addrMgr.fundManager();
        // address dao = addrMgr.dao();
        // address siwe = addrMgr.siweAuth();
        address userManager = addrMgr.userManager();

        if (exchange != address(0) && exchange != address(EXCHANGE)) {
            EXCHANGE = IExchange(exchange);
        }
        if (fundManager != address(0) && fundManager != address(FUND_MANAGER)) {
            FUND_MANAGER = IFundManager(fundManager);
        }
        // if (dao != address(0) && dao != DAO) {
        //     DAO = dao;
        // }
        // if (siwe != address(0) && siwe != address(SIWE_AUTH)) {
        //     SIWE_AUTH = ISiweAuth(siwe);
        // }
        if (userManager != address(0) && userManager != address(USER_MANAGER)) {
            USER_MANAGER = IUserManager(userManager);
        }
    }

    /**
     * @dev Set the increment rate
     * @param rate_ The increment rate
     * Default: 200 (200%)
     */
    function setIncrementRate(uint8 rate_) external onlyDAO {
        if (rate_ == 0 || rate_ > 200) revert InvalidRate();
        _incrementRate = rate_;
    }

    // ==========================================================================================================
    //                                      Getter Functions
    // ==========================================================================================================

    function incrementRate() external view returns (uint8) {
        return _incrementRate;
    }

    function nextBoxId() external view returns (uint256) {
        return _nextBoxId;
    }

    /**
     * @dev Get user id
     * @param user_ The address of user
     * @return The user id
     */
    // function getUserId(address user_) external returns (uint256) {
    //     uint256 userId = USER_MANAGER.getUserId(user_);
    //     return userId;
    // }
}
