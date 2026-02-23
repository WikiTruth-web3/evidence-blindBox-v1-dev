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

import {IUserId} from "@wikitruth-v1/interfaces/IUserId.sol";
import {ISiweAuth} from "../interfaces2/ISiweAuth.sol";
import {ITruthNFT} from "@wikitruth-v1/interfaces/ITruthNFT.sol";
import {IExchange} from "@wikitruth-v1/interfaces/IExchange.sol";
import {IFundManager} from "@wikitruth-v1/interfaces/IFundManager.sol";
import {IAddressManager} from "@wikitruth-v1/interfaces/IAddressManager.sol";

import {RelayerModifier} from "./RelayerModifier.sol";

/**
 * @title TruthBoxBaseRelayer
 * @dev ERC-2771 compatible version of TruthBoxBase
 */

abstract contract TruthBoxBaseRelayer is RelayerModifier {
    IUserId internal USER_ID;
    ISiweAuth internal SIWE_AUTH;
    ITruthNFT internal NFT;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;

    uint8 internal _incrementRate; // 2.0 * 100

    // =====================================================================================

    uint256 internal _boxCount;
    uint8 internal _minDeadlineDays;
    uint8 internal _maxDeadlineDays;
    uint8 internal _minPublicDays;
    uint8 internal _maxPublicDays;

    // ==================================================================================================
    uint256 internal _nextBoxId;

    // =====================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) RelayerModifier(addrManager_, trustedForwarder_) {
        _incrementRate = 200;
        _minDeadlineDays = 3;
        _maxDeadlineDays = 90;
        _minPublicDays = 1;
        _maxPublicDays = 14;
    }

    // =====================================================================================
    //                           internal: set address
    // =====================================================================================

    function _setAddress() internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        address nft = addrMgr.truthNFT();
        address exchange = addrMgr.exchange();
        address fundManager = addrMgr.fundManager();
        address siwe = addrMgr.siweAuth();
        address userId = addrMgr.userId();

        if (nft != address(0) && nft != address(NFT)) {
            NFT = ITruthNFT(nft);
        }
        if (exchange != address(0) && exchange != address(EXCHANGE)) {
            EXCHANGE = IExchange(exchange);
        }
        if (fundManager != address(0) && fundManager != address(FUND_MANAGER)) {
            FUND_MANAGER = IFundManager(fundManager);
        }
        if (siwe != address(0) && siwe != address(SIWE_AUTH)) {
            SIWE_AUTH = ISiweAuth(siwe);
        }
        if (userId != address(0) && userId != address(USER_ID)) {
            USER_ID = IUserId(userId);
        }
    }

    // =====================================================================================
    //                           external: set address (admin)
    // =====================================================================================

    function setAddress() external checkSetCaller {
        _setAddress();
    }

    // =====================================================================================
    //                              Set Deadline and Public Days
    // =====================================================================================

    function setMinDeadlineDays(uint8 minDeadlineDays_) external onlyAdminDAO {
        _minDeadlineDays = minDeadlineDays_;
    }

    function setMaxDeadlineDays(uint8 maxDeadlineDays_) external onlyAdminDAO {
        _maxDeadlineDays = maxDeadlineDays_;
    }

    function setMinPublicDays(uint8 minPublicDays_) external onlyAdminDAO {
        _minPublicDays = minPublicDays_;
    }

    function setMaxPublicDays(uint8 maxPublicDays_) external onlyAdminDAO {
        _maxPublicDays = maxPublicDays_;
    }

    /**
     * @dev Set the increment rate
     * @param rate_ The increment rate
     * Default: 200 (200%)
     */
    function setIncrementRate(uint8 rate_) external onlyDAO {
        if (rate_ == 0 || rate_ > 200) revert InvalidRate();
        _incrementRate = rate_;
    }

    // ==========================================================================================================
    //                                      Getter Functions
    // ==========================================================================================================

    function incrementRate() external view returns (uint8) {
        return _incrementRate;
    }

    function nextBoxId() external view returns (uint256) {
        return _nextBoxId;
    }
}
