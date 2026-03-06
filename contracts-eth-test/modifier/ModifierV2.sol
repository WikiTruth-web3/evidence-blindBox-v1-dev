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

import {
    IAddressManager
} from "@marketplace-v1/interfaces-eth/IAddressManager.sol";
import {SetAddress} from "../base/SetAddress.sol";
import {ProxyUpgrade} from "../proxy/ProxyUpgrade.sol";

contract ModifierV2 is ProxyUpgrade, SetAddress {
    // address internal ADMIN;

    // =======================================================================================================
    constructor(address addrManager_) SetAddress(addrManager_) {
        // ADMIN = msg.sender;
    }

    // function setAdmin(address admin_) external onlyAdmin {
    //     ADMIN = admin_;
    // }

    // function admin() external view returns (address) {
    //     return ADMIN;
    // }

    // =====================================================================================

    // modifier onlyAdmin() {
    //     if (msg.sender != ADMIN) revert NotAdmin();
    //     _;
    // }

    modifier onlyDAO() {
        if (msg.sender != ADDR_MANAGER.dao()) revert NotDAO();
        _;
    }

    modifier onlyAdminDAO() {
        if (msg.sender != ADDR_MANAGER.dao() && msg.sender != admin())
            revert NotAdminOrDAO();
        _;
    }

    modifier onlyManager() {
        if (msg.sender != address(ADDR_MANAGER) && msg.sender != admin()) {
            revert InvalidCaller();
        }
        _;
    }

    modifier onlyProjectContract() {
        if (!ADDR_MANAGER.isProjectContract(msg.sender)) {
            revert NotProjectCaller();
        }
        _;
    }
}
