// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

// import {IAddressManager} from "@interfaces/IAddressManager.sol";
import {Error} from "@interfaces/base/Error.sol";
import {Main} from "@interfaces/base/IContracts.sol";
/**
 * @title Modifier
 * @dev This contract is used to manage modifiers
 */

contract Modifier01 is Error {
    address internal ADMIN;

    // =======================================================================================================
    constructor() {
        ADMIN = msg.sender;
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

}
