// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

// import {
//     ReentrancyGuard
// } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {Pausable} from "../abstract/Pausable.sol";
import {IUserManager} from "@interfaces/sapphire/IUserManager.sol";
import {IFundManager} from "@interfaces/IFundManager.sol";
import {IExchange} from "@interfaces/IExchange.sol";
import {IAddressManager} from "@interfaces/IAddressManager.sol";
import {IBlindBox} from "@interfaces/sapphire/IBlindBox.sol";

import {Main} from "@interfaces/base/IContracts.sol";
import {Modifier} from "../modifier/Modifier.sol";


/**
 * @title UserManager01
 * @dev User management contract that supports multiple tokens
 */

contract UserManager01 is Modifier {
    // =====================================================================================
    // IBlindBox internal BLIND_BOX;
    // IUserManager internal USER_MANAGER;
    // IExchange internal EXCHANGE;
    // IFundManager internal FUND_MANAGER;
    address internal SIWE_AUTH;

    // =====================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
    }

    // =====================================================================================
    function _setContracts() internal {
        IAddressManager addrMgr = ADDR_MANAGER;

        address siwe = addrMgr.getMainContract(Main.SiweAuth);
        if (siwe != SIWE_AUTH ) {
            SIWE_AUTH = siwe;
        }

    }

    // ==========================================================================================================
    //                                         view get fee rate
    // ==========================================================================================================

}
