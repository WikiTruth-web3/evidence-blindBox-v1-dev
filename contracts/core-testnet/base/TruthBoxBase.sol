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

import {IUserId} from "@marketplace-v1/interfaces/IUserId.sol";
import {ISiweAuth} from "@marketplace-v1/interfaces-siwe/ISiweAuth.sol";
import {IFundManager} from "@marketplace-v1/interfaces/IFundManager.sol";
import {IExchange} from "@marketplace-v1/interfaces/IExchange.sol";
import {IAddressManager} from "@marketplace-v1/interfaces/IAddressManager.sol";

import {Modifier} from "../modifier/Modifier.sol";
/**
 *  @notice TruthBoxBase
 *
 */

contract TruthBoxBase is Modifier {
    IUserId internal USER_ID;
    ISiweAuth internal SIWE_AUTH;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;

    uint8 internal _incrementRate; // 2.0 * 100

    // ==================================================================================================
    uint256 internal _nextBoxId;

    // ==================================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
        _incrementRate = 200;
    }
    // ==================================================================================================

    // ==========================================================================================================

    // TODO Add the address of the DAO fund manager
    function _setAddress() internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        address exchange = addrMgr.exchange();
        address fundManager = addrMgr.fundManager();
        address siwe = addrMgr.siweAuth();
        address userId = addrMgr.userId();

        if (exchange != address(0) && exchange != address(EXCHANGE)) {
            EXCHANGE = IExchange(exchange);
        }
        if (fundManager != address(0) && fundManager != address(FUND_MANAGER)) {
            FUND_MANAGER = IFundManager(fundManager);
        }
        if (siwe != address(0) && siwe != address(SIWE_AUTH)) {
            SIWE_AUTH = ISiweAuth(siwe);
        }
        if (userId != address(0) && userId != address(USER_ID)) {
            USER_ID = IUserId(userId);
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
}
