// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "../abstract/Pausable.sol";
import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {IFundManager} from "@interfaces/IFundManager.sol";
import {IExchange} from "@interfaces/IExchange.sol";
import {IAddressManager} from "@interfaces/IAddressManager.sol";
import {IBlindBox} from "@interfaces/eth/IBlindBox.sol";

import {Main} from "@interfaces/base/IContracts.sol";
import {Modifier} from "../modifier/Modifier.sol";

// import {SetContracts} from "../modifier/SetContracts.sol";

/**
 * @title FundManager01
 * @dev Fund management contract that supports multiple tokens
 */

contract FundManager01 is Modifier, ReentrancyGuard, Pausable {
    event BuyerRefundRateAdded(uint256 boxId, uint8 rate);
    event DaoFeeRateAdded(uint256 boxId, uint8 rate);
    // =====================================================================================
    IBlindBox internal BLIND_BOX;
    IUserManager internal USER_MANAGER;
    IExchange internal EXCHANGE;
    // IFundManager internal FUND_MANAGER;
    address internal DAO_TREASURY;

    // rate / 1000 = %
    /**
     * @dev The official service fee rate
     */
    uint8 internal _serviceFeeRate;
    uint8 internal _helperFeeRate;


    // =====================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
        _serviceFeeRate = 30; // 30
        _helperFeeRate = 10; // 10
    }

    // =====================================================================================
    function _setContracts() internal {
        IAddressManager addrMgr = ADDR_MANAGER;

        address blindBox = addrMgr.getMainContract(Main.BlindBox);
        if (blindBox != address(BLIND_BOX)) {
            BLIND_BOX = IBlindBox(blindBox);
        }

        address exchange = addrMgr.getMainContract(Main.Exchange);
        if (exchange != address(EXCHANGE)) {
            EXCHANGE = IExchange(exchange);
        }

        // address fundManager = addrMgr.getMainContract(Main.FundManager);
        // if (fundManager != address(FUND_MANAGER) ) {
        //     FUND_MANAGER = IFundManager(fundManager);
        // }

        address userManager = addrMgr.getMainContract(Main.UserManager);
        if (userManager != address(USER_MANAGER) ) {
            USER_MANAGER = IUserManager(userManager);
        }

        address daoTreasury = addrMgr.getMainContract(Main.DaoTreasury);
        if (daoTreasury != DAO_TREASURY ) {
            DAO_TREASURY = daoTreasury;
        }

    }

    // =====================================================================================
    //                                  Management Functions
    // =====================================================================================

    function pause() external onlyAdminDAO {
        _pause();
    }

    function unpause() external onlyAdminDAO {
        _unpause();
    }

    // =====================================================================================================

    // ==========================================================================================================

    /**
     * @dev Set service fee rate
     * @param Rate_ The service fee rate
     * Can be set to 0-50
     */
    function setServiceFeeRate(uint8 Rate_) external onlyDAO {
        if (Rate_ > 50) revert InvalidRate();
        _serviceFeeRate = Rate_;
    }

    function setHelperFeeRate(uint8 Rate_) external onlyDAO {
        if (Rate_ > 30) revert InvalidRate();
        _helperFeeRate = Rate_;
    }

    // ==========================================================================================================
    //                                         view get fee rate
    // ==========================================================================================================

    function serviceFeeRate() external view returns (uint8) {
        return _serviceFeeRate;
    }

    function helperFeeRate() external view returns (uint8) {
        return _helperFeeRate;
    }

}
