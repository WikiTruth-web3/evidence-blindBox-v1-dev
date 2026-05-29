// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

// import {
//     ReentrancyGuard
// } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {Pausable} from "../abstract/Pausable.sol";
import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {IFundManager} from "@interfaces/eth/IFundManager.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";

import {Main} from "@interfaces/IContracts.sol";
import {Modifier} from "../modifier/Modifier.sol";


/**
 * @title Forwarder01
 * @dev Forwarder contract that supports multiple tokens
 */

contract Forwarder01 is Modifier {
    error RelayerIsBlacklisted();

    // =====================================================================================
    // IBlindBox internal BLIND_BOX;
    IUserManager internal USER_MANAGER;
    // IExchange internal EXCHANGE;
    // IFundManager internal FUND_MANAGER;

    mapping(address => bool) internal _targetWhitelist;

    uint256 internal _maxGasLimit;


    // =====================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
    }

    // =====================================================================================
    function _setContracts() internal {
        IAddressManager addrMgr = ADDR_MANAGER;

        // address blindBox = addrMgr.getMainContract(Main.BlindBox);
        // if (blindBox != address(BLIND_BOX)) {
        //     BLIND_BOX = IBlindBox(blindBox);
        // }

        // address exchange = addrMgr.getMainContract(Main.Exchange);
        // if (exchange != address(EXCHANGE)) {
        //     EXCHANGE = IExchange(exchange);
        // }

        // address fundManager = addrMgr.getMainContract(Main.FundManager);
        // if (fundManager != address(FUND_MANAGER) ) {
        //     FUND_MANAGER = IFundManager(fundManager);
        // }

        address userManager = addrMgr.getMainContract(Main.UserManager);
        if (userManager != address(USER_MANAGER) ) {
            USER_MANAGER = IUserManager(userManager);
        }

    }

    // =====================================================================================
    //                                     Modifiers
    // =====================================================================================

    modifier onlyValidRelayer() {
        if (
            address(USER_MANAGER) != address(0) &&
            USER_MANAGER.isBlacklisted(msg.sender)
        ) {
            revert RelayerIsBlacklisted();
        }
        _;
    }

    // =====================================================================================

    function setTargetStatus(address target_, bool status_) external onlyAdmin {
        _targetWhitelist[target_] = status_;
    }

    function setMaxGasLimit(uint256 maxGasLimit_) external onlyAdmin {
        _maxGasLimit = maxGasLimit_;
    }


    // =====================================================================================
    //                                     Getters
    // =====================================================================================

    function isTargetWhitelisted(address target_) external view returns (bool) {
        return _targetWhitelist[target_];
    }

    function getMaxGasLimit() external view returns (uint256) {
        return _maxGasLimit;
    }
}
