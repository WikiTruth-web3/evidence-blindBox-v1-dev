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

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import {IUserId} from "@wikitruth-v1/interfaces/IUserId.sol";
import {ISiweAuth} from "../interfaces2/ISiweAuth.sol";
import {ITruthBox} from "@wikitruth-v1/interfaces/ITruthBox.sol";
import {IExchange} from "@wikitruth-v1/interfaces/IExchange.sol";
import {IAddressManager} from "@wikitruth-v1/interfaces/IAddressManager.sol";

import {ISwapRouter} from "../interfaces2/ISwapRouter.sol";
import {IQuoter} from "../interfaces2/IQuoter.sol";

import {FeeRateRelayer} from "./FeeRateRelayer.sol";

/**
 *  @title FundManagerBaseRelayer
 *  @dev ERC-2771 compatible version of FundManagerBase
 */

contract FundManagerBaseRelayer is FeeRateRelayer, ReentrancyGuard, Pausable {
    ITruthBox internal TRUTH_BOX;
    IExchange internal EXCHANGE;
    IUserId internal USER_ID;
    ISiweAuth internal SIWE_AUTH;

    address internal SWAP_CONTRACT;

    // =====================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) FeeRateRelayer(addrManager_, trustedForwarder_) {}

    // =====================================================================================
    //                           internal: set address
    // =====================================================================================

    function _setAddress() internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        address truthBox = addrMgr.truthBox();
        address exchange = addrMgr.exchange();
        address userId = addrMgr.userId();
        address siweAuth = addrMgr.siweAuth();
        address swapContract = addrMgr.swapContract();

        if (truthBox != address(0) && truthBox != address(TRUTH_BOX)) {
            TRUTH_BOX = ITruthBox(truthBox);
        }
        if (exchange != address(0) && exchange != address(EXCHANGE)) {
            EXCHANGE = IExchange(exchange);
        }

        if (userId != address(0) && userId != address(USER_ID)) {
            USER_ID = IUserId(userId);
        }
        if (siweAuth != address(0) && siweAuth != address(SIWE_AUTH)) {
            SIWE_AUTH = ISiweAuth(siweAuth);
        }
        if (swapContract != address(0) && swapContract != SWAP_CONTRACT) {
            SWAP_CONTRACT = swapContract;
        }
    }

    // =====================================================================================
    //                           external: set address (admin)
    // =====================================================================================

    function setAddress() external checkSetCaller {
        _setAddress();
    }

    // =====================================================================================
    //                           Pause / Unpause
    // =====================================================================================

    function pause() external onlyAdminDAO {
        _pause();
    }

    function unpause() external onlyAdminDAO {
        _unpause();
    }
}
