// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

// import {
//     ReentrancyGuard
// } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {Pausable} from "../abstract/Pausable.sol";
import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {IFundManager} from "@interfaces/IFundManager.sol";
import {IExchange} from "@interfaces/IExchange.sol";
import {IAddressManager} from "@interfaces/IAddressManager.sol";
import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";

import {Main} from "@interfaces/base/IContracts.sol";
import {Modifier} from "../modifier/Modifier.sol";


/**
 * @title UserManager01
 * @dev User management contract that supports multiple tokens
 */

contract UserManager01 is Modifier {
    // =====================================================================================
    IBlindBox internal BLIND_BOX;
    // IUserManager internal USER_MANAGER;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;

    // =====================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
    }

    // =====================================================================================
    function _setContracts() internal {
        IAddressManager addrMgr = ADDR_MANAGER;

        address blindBox = addrMgr.getMainContract(Main.BlindBox);
        if (blindBox != address(BLIND_BOX)) {
            BLIND_BOX = IBlindBox(blindBox);
        }

        address exchange = addrMgr.getMainContract(Main.Exchange);
        if (exchange != address(EXCHANGE)) {
            EXCHANGE = IExchange(exchange);
        }

        address fundManager = addrMgr.getMainContract(Main.FundManager);
        if (fundManager != address(FUND_MANAGER) ) {
            FUND_MANAGER = IFundManager(fundManager);
        }

        // address userManager = addrMgr.getMainContract(Main.UserManager);
        // if (userManager != address(USER_MANAGER) ) {
        //     USER_MANAGER = IUserManager(userManager);
        // }

    }

    // ==========================================================================================================
    //                                         view get fee rate
    // ==========================================================================================================

}
