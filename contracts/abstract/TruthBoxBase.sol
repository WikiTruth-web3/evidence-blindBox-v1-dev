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
import {ITruthBox} from "@wikitruth-v1/interfaces/ITruthBox.sol";
import {IFundManager} from "@wikitruth-v1/interfaces/IFundManager.sol";
import {IDaoFundManager} from "@wikitruth-v1/interfaces/IDaoFundManager.sol";
import {IExchange} from "@wikitruth-v1/interfaces/IExchange.sol";
import {IAddressManager} from "@wikitruth-v1/interfaces/IAddressManager.sol";

// import "./library.sol";
import {Modifier} from "./Modifier.sol";
/**
 *  @notice TruthBoxBase
 *
 */

contract TruthBoxBase is Modifier {
    IUserId internal USER_ID;
    ISiweAuth internal SIWE_AUTH;
    ITruthNFT internal NFT;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;
    IDaoFundManager internal DAO_FUND_MANAGER;

    uint8 internal _incrementRate; // 2.0 * 100

    // ==================================================================================================
    uint256 internal _nextBoxId;

    // ==================================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
        _incrementRate = 200;
    }
    // ==================================================================================================

    // ==========================================================================================================

    // TODO Add the address of the DAO fund manager
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
