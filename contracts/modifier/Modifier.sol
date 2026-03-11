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

import {IAddressManager} from "@marketplace-v1/interfaces/IAddressManager.sol";
import {Error} from "@marketplace-v1/interfaces/Error.sol";

/**
 * @title Modifier
 * @dev This contract is used to manage modifiers
 */

contract Modifier is Error {
    IAddressManager internal ADDR_MANAGER;
    address internal ADMIN;

    // =======================================================================================================
    constructor(address addrManager_) {
        ADMIN = msg.sender;
        ADDR_MANAGER = IAddressManager(addrManager_);
    }

    function setAddressManager(address addrManager_) external onlyAdmin {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }

    function setAdmin(address admin_) external onlyAdmin {
        ADMIN = admin_;
    }

    // function admin() external view returns (address) {
    //     return ADMIN;
    // }

    // =====================================================================================

    modifier onlyAdmin() {
        if (msg.sender != ADMIN) revert NotAdmin();
        _;
    }

    modifier onlyDAO() {
        if (msg.sender != ADDR_MANAGER.dao()) revert NotDAO();
        _;
    }

    modifier onlyAdminDAO() {
        if (msg.sender != ADDR_MANAGER.dao() && msg.sender != ADMIN)
            revert NotAdminOrDAO();
        _;
    }

    modifier onlyManager() {
        if (msg.sender != address(ADDR_MANAGER) && msg.sender != ADMIN) {
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
