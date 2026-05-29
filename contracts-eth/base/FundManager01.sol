// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "../abstract/Pausable.sol";

import {SetContracts} from "../modifier/SetContracts.sol";

/**
 * @title FundManager01
 * @dev Fund management contract that supports multiple tokens
 */

contract FundManager01 is SetContracts, ReentrancyGuard, Pausable {
    event BuyerRefundRateAdded(uint256 boxId, uint8 rate);
    event DaoFeeRateAdded(uint256 boxId, uint8 rate);
    // =====================================================================================

    // rate / 1000 = %
    /**
     * @dev The official service fee rate
     */
    uint8 internal _serviceFeeRate;
    uint8 internal _helperFeeRate;


    // =====================================================================================
    constructor(address addrManager_) SetContracts(addrManager_) {
        _serviceFeeRate = 30; // 30
        _helperFeeRate = 10; // 10
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
