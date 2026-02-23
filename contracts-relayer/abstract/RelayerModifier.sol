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

import {IAddressManager} from "@wikitruth-v1/interfaces/IAddressManager.sol";

import {ProxyUpgrade} from "./ProxyUpgrade.sol";
import {ERC2771Handler} from "./ERC2771Handler.sol";

/**
 * @title RelayerModifier
 * @dev ERC-2771 compatible version of Modifier.
 * Inherits ERC2771Handler for _msgSender() and _msgData().
 * Admin/DAO/ProjectContract modifiers still use raw msg.sender
 * because admin operations should NEVER go through the relayer.
 */
contract RelayerModifier is ProxyUpgrade, ERC2771Handler {
    IAddressManager internal ADDR_MANAGER;

    // =======================================================================================================
    constructor(
        address addrManager_,
        address trustedForwarder_
    ) ERC2771Handler(trustedForwarder_) {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }

    // =====================================================================================
    //                              Address Manager
    // =====================================================================================

    function setAddressManager(address addrManager_) external onlyAdmin {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }

    // =====================================================================================
    //                    Modifiers (admin functions use raw msg.sender)
    // =====================================================================================

    modifier onlyDAO() {
        if (msg.sender != ADDR_MANAGER.dao()) revert NotDAO();
        _;
    }

    modifier onlyProjectContract() {
        if (!ADDR_MANAGER.isProjectContract(msg.sender)) {
            revert InvalidCaller();
        }
        _;
    }

    modifier onlyAdminDAO() {
        if (msg.sender != ADDR_MANAGER.dao() && msg.sender != admin())
            revert NotAdminOrDAO();
        _;
    }

    modifier checkSetCaller() {
        if (msg.sender != address(ADDR_MANAGER) && msg.sender != admin()) {
            revert InvalidCaller();
        }
        _;
    }
}
