// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IAddressManager} from "@interfaces/IAddressManager.sol";
import {Error} from "@interfaces/base/Error.sol";
import {Main} from "@interfaces/base/IContracts.sol";
/**
 * @title Modifier
 * @dev This contract is used to manage modifiers
 */

contract Modifier02 is Error {
    address internal ADMIN;
    IAddressManager internal ADDR_MANAGER;

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

    function admin() external view returns (address) {
        return ADMIN;
    }

    // =====================================================================================

    modifier onlyAdmin() {
        if (msg.sender != ADMIN) revert NotAdmin();
        _;
    }

    modifier onlyAdminDAO() {
        if (msg.sender != ADDR_MANAGER.getMainContract(Main.Dao) && msg.sender != ADMIN)
            revert NotAdminOrDAO();
        _;
    }

}
