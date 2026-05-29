// SPDX-License-Identifier: GPL-2.0-or-later
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.24;

import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {IFundManager} from "@interfaces/eth/IFundManager.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";

import {Main} from "@interfaces/IContracts.sol";
import {Modifier} from "../modifier/Modifier.sol";

// import {SetContracts} from "../modifier/SetContracts.sol";

/**
 *  @title Exchange01
 *  @dev This contract is used to manage the exchange
 *  @dev Inherits SetContracts to support modifiers
 */

contract Exchange01 is Modifier {
    error NotBuyContract();
    IBlindBox internal BLIND_BOX;
    IUserManager internal USER_MANAGER;
    // IExchange internal EXCHANGE;
    IFundManager internal FUND_MANAGER;

    uint256 internal _refundRequestPeriod;
    uint256 internal _arbitrationPeriod;

    uint8 internal _bidIncrementRate;

    // ========================================================================================================

    constructor(address addrManager_) Modifier(addrManager_) {
        _bidIncrementRate = 110;
        _refundRequestPeriod = 7 days;
        _arbitrationPeriod = 15 days;
    }

    // ========================================================================================================
    function _setContracts() internal {
        IAddressManager addrMgr = ADDR_MANAGER;

        address blindBox = addrMgr.getMainContract(Main.BlindBox);
        if (blindBox != address(BLIND_BOX)) {
            BLIND_BOX = IBlindBox(blindBox);
        }

        // address exchange = addrMgr.getMainContract(Main.Exchange);
        // if (exchange != address(EXCHANGE)) {
        //     EXCHANGE = IExchange(exchange);
        // }

        address fundManager = addrMgr.getMainContract(Main.FundManager);
        if (fundManager != address(FUND_MANAGER) ) {
            FUND_MANAGER = IFundManager(fundManager);
        }

        address userManager = addrMgr.getMainContract(Main.UserManager);
        if (userManager != address(USER_MANAGER) ) {
            USER_MANAGER = IUserManager(userManager);
        }

    }

    // =====================================================================================
    //                                      Basic Parameter Settings
    // =====================================================================================

    // 7~15  || 1~7
    function setRefundRequestPeriod(uint256 period_) external onlyDAO {
        if (period_ < 7 days || period_ > 15 days) revert InvalidPeriod();
        _refundRequestPeriod = period_;
    }
    // 15~60  || 1~7
    function setArbitrationPeriod(uint256 period_) external onlyDAO {
        if (period_ < 15 days || period_ > 60 days) revert InvalidPeriod();
        _arbitrationPeriod = period_;
    }

    // 110
    function setBidIncrementRate(uint8 rate_) external onlyDAO {
        if (rate_ <= 100 || rate_ > 150) revert InvalidRate();
        _bidIncrementRate = rate_;
    }

    // ========================================================================================================
    //                                           Getter function
    // ========================================================================================================

    function refundRequestPeriod() external view returns (uint256) {
        return _refundRequestPeriod;
    }
    function arbitrationPeriod() external view returns (uint256) {
        return _arbitrationPeriod;
    }
    function bidIncrementRate() external view returns (uint8) {
        return _bidIncrementRate;
    }


}
