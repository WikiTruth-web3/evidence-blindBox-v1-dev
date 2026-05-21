// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {IFundManager} from "@interfaces/eth/IFundManager.sol";
import {IFundManagerCrossChain} from "@interfaces/eth/IFundManagerCrossChain.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";

import {CoreContracts} from "@interfaces/IContracts.sol";

/**
 *  @notice SetAddress
 *
 */

contract SetAddress {
    IAddressManager internal ADDR_MANAGER;
    IBlindBox internal BLIND_BOX;

    IUserManager internal USER_MANAGER;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;
    IFundManagerCrossChain internal FUND_MANAGER_CROSS_CHAIN;

    // ==================================================================================================
    constructor(address addrManager_) {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }
    // ==================================================================================================

    function _setAddressManager(address addrManager_) internal {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }
    // ==========================================================================================================

    // TODO Add the address of the DAO fund manager
    function _setAddress(CoreContracts enum_) internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        // address siweAuth = addrMgr.siweAuth();
        address blindBox = addrMgr.blindBox();
        address exchange = addrMgr.exchange();
        address fundManager = addrMgr.fundManager();
        address fundManagerCrossChain = addrMgr.fundManagerCrossChain();
        address userManager = addrMgr.userManager();

        if (
            blindBox != address(0) &&
            blindBox != address(BLIND_BOX) &&
            enum_ != CoreContracts.BlindBox
        ) {
            BLIND_BOX = IBlindBox(blindBox);
        }

        if (
            exchange != address(0) &&
            exchange != address(EXCHANGE) &&
            enum_ != CoreContracts.Exchange
        ) {
            EXCHANGE = IExchange(exchange);
        }
        if (
            fundManager != address(0) &&
            fundManager != address(FUND_MANAGER) &&
            enum_ != CoreContracts.FundManager
        ) {
            FUND_MANAGER = IFundManager(fundManager);
        }
        if (
            fundManagerCrossChain != address(0) &&
            fundManagerCrossChain != address(FUND_MANAGER_CROSS_CHAIN) &&
            enum_ != CoreContracts.FundManagerCrossChain
        ) {
            FUND_MANAGER_CROSS_CHAIN = IFundManagerCrossChain(fundManagerCrossChain);
        }

        if (
            userManager != address(0) &&
            userManager != address(USER_MANAGER) &&
            enum_ != CoreContracts.UserManager
        ) {
            USER_MANAGER = IUserManager(userManager);
        }
    }
}
