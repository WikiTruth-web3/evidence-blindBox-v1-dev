// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {ProxyUpgrade} from "../proxy/ProxyUpgrade.sol";

contract ModifierV2 is ProxyUpgrade {
    // address internal ADMIN;
    IAddressManager internal ADDR_MANAGER;


    // =======================================================================================================
    constructor(address addrManager_) {
        // ADMIN = msg.sender;
        ADDR_MANAGER = IAddressManager(addrManager_);

    }

    // function setAdmin(address admin_) external onlyAdmin {
    //     ADMIN = admin_;
    // }

    // function admin() external view returns (address) {
    //     return ADMIN;
    // }

    function _setAddressManager(address addrManager_) internal {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }

    // =====================================================================================

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
