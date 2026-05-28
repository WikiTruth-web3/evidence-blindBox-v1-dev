// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {IFundManager} from "@interfaces/eth/IFundManager.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";

import {Main} from "@interfaces/IContracts.sol";
import {ModifierV2} from "./ModifierV2.sol";

/**
 *  @notice SetContracts
 *
 */

contract SetContracts is ModifierV2 {
    IBlindBox internal BLIND_BOX;
    IUserManager internal USER_MANAGER;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;

    // ==================================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
    }
    // ==================================================================================================

    function _setContracts(Main enum_) internal {
        IAddressManager addrMgr = ADDR_MANAGER;

        if (enum_ != Main.BlindBox) {
            address blindBox = addrMgr.getMainContract(Main.BlindBox);
            if (blindBox != address(BLIND_BOX)) {
                BLIND_BOX = IBlindBox(blindBox);
            }
        }
        if (enum_ != Main.Exchange) {
            address exchange = addrMgr.getMainContract(Main.Exchange);
            if (exchange != address(EXCHANGE)) {
                EXCHANGE = IExchange(exchange);
            }
        }
        if (enum_ != Main.FundManager) {
            address fundManager = addrMgr.getMainContract(Main.FundManager);
            if (fundManager != address(FUND_MANAGER) ) {
                FUND_MANAGER = IFundManager(fundManager);
            }
        }
        if (enum_ != Main.UserManager) {
            address userManager = addrMgr.getMainContract(Main.UserManager);
            if (userManager != address(USER_MANAGER) ) {
                USER_MANAGER = IUserManager(userManager);
            }
        }
    }
}
