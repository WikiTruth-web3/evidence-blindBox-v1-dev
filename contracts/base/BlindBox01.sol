// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IUserManager} from "@interfaces/sapphire/IUserManager.sol";
import {IFundManager} from "@interfaces/IFundManager.sol";
import {IExchange} from "@interfaces/IExchange.sol";
import {IAddressManager} from "@interfaces/IAddressManager.sol";
import {IBlindBox} from "@interfaces/sapphire/IBlindBox.sol";

import {Main} from "@interfaces/base/IContracts.sol";
import {Modifier} from "../modifier/Modifier.sol";

// import {SetContracts} from "../modifier/SetContracts.sol";
/**
 *  @notice BlindBox01
 *  This contract defines the basic variables and functions of BlindBox
 */

contract BlindBox01 is Modifier {
    address internal SIWE_AUTH;
    IUserManager internal USER_MANAGER;
    IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;

    uint8 internal _incrementRate; // 2.0 * 100

    uint256 internal _nextBoxId;

    // ==================================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
        _incrementRate = 200;
    }
    // ========================================================================================================

    function _setContracts() internal {
        IAddressManager addrMgr = ADDR_MANAGER;

        address siwe = addrMgr.getMainContract(Main.SiweAuth);
        if (siwe != SIWE_AUTH ) {
            SIWE_AUTH = siwe;
        }

        address exchange = addrMgr.getMainContract(Main.Exchange);
        if (exchange != address(EXCHANGE)) {
            EXCHANGE = IExchange(exchange);
        }

        address fundManager = addrMgr.getMainContract(Main.FundManager);
        if (fundManager != address(FUND_MANAGER) ) {
            FUND_MANAGER = IFundManager(fundManager);
        }

        address userManager = addrMgr.getMainContract(Main.UserManager);
        if (userManager != address(USER_MANAGER) ) {
            USER_MANAGER = IUserManager(userManager);
        }

    }

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
