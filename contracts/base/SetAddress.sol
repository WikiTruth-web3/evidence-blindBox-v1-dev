// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IUserManager} from "@interfaces/sapphire/IUserManager.sol";
import {IFundManager} from "@interfaces/sapphire/IFundManager.sol";
import {IExchange} from "@interfaces/sapphire/IExchange.sol";
import {IAddressManager} from "@interfaces/sapphire/IAddressManager.sol";
import {IBlindBox} from "@interfaces/sapphire/IBlindBox.sol";

import {CoreContracts} from "@interfaces/IContracts.sol";

/**
 *  @notice SetAddress
 *
 */

contract SetAddress {
    IAddressManager internal ADDR_MANAGER;
    address internal SIWE_AUTH;

    IUserManager internal USER_MANAGER;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;
    IBlindBox internal BLIND_BOX;

    // ==================================================================================================
    constructor(address addrManager_) {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }
    // ==================================================================================================

    function _setAddressManager(address addrManager_) internal {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }
    // ==================================================================================================

    // TODO Add the address of the DAO fund manager
    function _setAddress(CoreContracts enum_) internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        address siweAuth = addrMgr.siweAuth();
        address blindBox = addrMgr.blindBox();
        address exchange = addrMgr.exchange();
        address fundManager = addrMgr.fundManager();
        address userManager = addrMgr.userManager();

        if (siweAuth != address(0) && siweAuth != address(SIWE_AUTH)) {
            SIWE_AUTH = siweAuth;
        }

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
            userManager != address(0) &&
            userManager != address(USER_MANAGER) &&
            enum_ != CoreContracts.UserManager
        ) {
            USER_MANAGER = IUserManager(userManager);
        }
    }
}
