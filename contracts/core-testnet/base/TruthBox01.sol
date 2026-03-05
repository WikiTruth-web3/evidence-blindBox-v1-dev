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
import {CoreContracts} from "@marketplace-v1/interfaces/IContracts.sol";

import {ModifierV2} from "../modifier/ModifierV2.sol";
/**
 *  @notice TruthBox01
 *  This contract defines the basic variables and functions of TruthBox
 */

contract TruthBox01 is ModifierV2 {
    uint8 internal _incrementRate; // 2.0 * 100

    uint256 internal _nextBoxId;

    // ==================================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
        _incrementRate = 200;
    }

    /**
     * @notice Set the contract address
     * @dev Get and set the related contract addresses from AddressManager
     */
    function setAddress() external onlyManager {
        _setAddress(CoreContracts.TruthBox);
    }
    // ==================================================================================================

    // ==========================================================================================================
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
