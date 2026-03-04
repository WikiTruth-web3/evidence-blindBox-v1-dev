// SPDX-License-Identifier: GPL-2.0-or-later

/**
 *         ██╗    ██╗██╗██╗  ██╗██╗    ████████╗██████╗ ██╗   ██╗████████╗██╗  ██╗
 *         ██║    ██║██║██║ ██╔╝██║    ╚══██╔══╝██╔══██╗██║   ██║╚══██╔══╝██║  ██║
 *         ██║ █╗ ██║██║█████╔╝ ██║       ██║   ██████╔╝██║   ██║   ██║   ███████║
 *         ██║███╗██║██║██╔═██╗ ██║       ██║   ██╔══██╗██║   ██║   ██║   ██╔══██║
 *         ╚███╔███╔╝██║██║  ██╗██║       ██║   ██║  ██║╚██████╔╝   ██║   ██║  ██║
 *          ╚══╝╚══╝ ╚═╝╚═╝  ╚═╝╚═╝       ╚═╝   ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝
 *
 *  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
 *  ┃                        Website: https://wikitruth.eth.limo/                         ┃
 *  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
 */

pragma solidity ^0.8.24;

import {IUserManager} from "@marketplace-v1/interfaces/IUserManager.sol";
import {IFundManager} from "@marketplace-v1/interfaces/IFundManager.sol";
import {IExchange} from "@marketplace-v1/interfaces/IExchange.sol";
import {IAddressManager} from "@marketplace-v1/interfaces/IAddressManager.sol";
import {ITruthBox} from "@marketplace-v1/interfaces/ITruthBox.sol";

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
    ITruthBox internal TRUTH_BOX;

    // ==================================================================================================
    constructor(address addrManager_) {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }
    // ==================================================================================================

    function setAddressManager(address addrManager_) internal {
        ADDR_MANAGER = IAddressManager(addrManager_);
    }
    // ==========================================================================================================

    // TODO Add the address of the DAO fund manager
    function _setAddress(string memory contractName_) internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        address truthBox = addrMgr.truthBox();
        address exchange = addrMgr.exchange();
        address fundManager = addrMgr.fundManager();
        address siweAuth = addrMgr.siweAuth();
        address userManager = addrMgr.userManager();

        if (
            siweAuth != address(0) &&
            siweAuth != SIWE_AUTH &&
            contractName_ != "SiweAuth"
        ) {
            SIWE_AUTH = siweAuth;
        }

        if (
            truthBox != address(0) &&
            truthBox != TRUTH_BOX &&
            contractName_ != "TruthBox"
        ) {
            TRUTH_BOX = ITruthBox(truthBox);
        }

        if (
            exchange != address(0) &&
            exchange != address(EXCHANGE) &&
            contractName_ != "Exchange"
        ) {
            EXCHANGE = IExchange(exchange);
        }
        if (
            fundManager != address(0) &&
            fundManager != address(FUND_MANAGER) &&
            contractName_ != "FundManager"
        ) {
            FUND_MANAGER = IFundManager(fundManager);
        }

        if (
            userManager != address(0) &&
            userManager != address(USER_MANAGER) &&
            contractName_ != "UserManager"
        ) {
            USER_MANAGER = IUserManager(userManager);
        }
    }
}
