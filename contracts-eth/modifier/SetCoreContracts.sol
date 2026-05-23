// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {IFundManager} from "@interfaces/eth/IFundManager.sol";
import {IFundManagerVirtual} from "@interfaces/eth/IFundManagerVirtual.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";

import {CoreContracts} from "@interfaces/IContracts.sol";
import {ModifierV2} from "./ModifierV2.sol";

/**
 *  @notice SetCoreContracts
 *
 */

contract SetCoreContracts is ModifierV2 {
    IBlindBox internal BLIND_BOX;
    IUserManager internal USER_MANAGER;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;

    // ==================================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
    }
    // ==================================================================================================

    function _setCoreContracts(CoreContracts enum_) internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        if (enum_ != CoreContracts.BlindBox) {
            address blindBox = addrMgr.getCoreContract(CoreContracts.BlindBox);
            if (blindBox != address(BLIND_BOX)) {
                BLIND_BOX = IBlindBox(blindBox);
            }
        }
        if (enum_ != CoreContracts.Exchange) {
            address exchange = addrMgr.getCoreContract(CoreContracts.Exchange);
            if (exchange != address(EXCHANGE)) {
                EXCHANGE = IExchange(exchange);
            }
        }
        if (enum_ != CoreContracts.FundManager) {
            address fundManager = addrMgr.getCoreContract(CoreContracts.FundManager);
            if (fundManager != address(FUND_MANAGER) ) {
                FUND_MANAGER = IFundManager(fundManager);
            }
        }
        if (enum_ != CoreContracts.UserManager) {
            address userManager = addrMgr.getCoreContract(CoreContracts.UserManager);
            if (userManager != address(USER_MANAGER) ) {
                USER_MANAGER = IUserManager(userManager);
            }
        }
    }
}
