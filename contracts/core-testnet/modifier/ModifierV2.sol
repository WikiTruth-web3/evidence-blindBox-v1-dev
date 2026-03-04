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

import {SetAddress} from "../base/SetAddress.sol";

import {IAddressManager} from "@marketplace-v1/interfaces/IAddressManager.sol";
import {ProxyUpgrade} from "../proxy/ProxyUpgrade.sol";

/**
 * @title Modifier
 * @dev This contract is used to manage modifiers
 * @dev Inherits ERC2771Context to support meta-transactions
 */

contract ModifierSetAddress is ProxyUpgrade, SetAddress {
    // address internal ADMIN;

    // =======================================================================================================
    constructor(address addrManager_) SetAddress(addrManager_) {
        // ADMIN = msg.sender;
    }

    function setAddressManager(address addrManager_) external onlyAdmin {
        _setAddressManager(addrManager_);
    }

    // function setAdmin(address admin_) external onlyAdmin {
    //     ADMIN = admin_;
    // }

    // function admin() external view returns (address) {
    //     return ADMIN;
    // }

    // =====================================================================================

    /**
     * @dev The admin is managed by the ProxyUpgrade contract
     * The modifier will be re-enabled in the production environment
     */
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
            revert InvalidCaller();
        }
        _;
    }
}
