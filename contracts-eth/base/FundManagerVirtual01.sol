// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IFundManager} from "@interfaces/eth/IFundManager.sol";
import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";

import {ModifierV3} from "../modifier/ModifierV3.sol";

import {PeripheralContracts, CoreContracts} from "@interfaces/IContracts.sol";

/**
 *  @notice Peripheral Fund Manager
 *
 */

contract FundManagerVirtual01 is ModifierV3{

    IExchange internal EXCHANGE;
    IUserManager internal USER_MANAGER;
    IFundManager internal FUND_MANAGER;

    // ==================================================================================================
    constructor(address addrManager_, address executor_) ModifierV3(addrManager_) {

    }

    // ==================================================================================================

    function _setContracts() internal onlyManager {
        IAddressManager addrMgr = ADDR_MANAGER;
        address userManager = addrMgr.getCoreContract(CoreContracts.UserManager);
        address fundManager = addrMgr.getCoreContract(CoreContracts.FundManager);
        address exchange = addrMgr.getCoreContract(CoreContracts.Exchange);
        
        if (exchange != address(EXCHANGE )) {
            EXCHANGE = IExchange(exchange);
        }
        if (fundManager != address(FUND_MANAGER) ) {
            FUND_MANAGER = fundManager;
        }
        if (userManager != address(USER_MANAGER) ) {
            USER_MANAGER = userManager;
        }

    }
}
