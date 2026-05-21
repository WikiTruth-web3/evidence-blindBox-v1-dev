// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "../abstract/Pausable.sol";

import {ModifierV2} from "../modifier/ModifierV2.sol";

/**
 * @title FundManager01
 * @dev Fund management contract that supports multiple tokens
 */

contract FundManager01 is ModifierV2, ReentrancyGuard, Pausable {
    event BuyerRefundRateAdded(uint256 boxId, uint8 rate);
    event DaoFeeRateAdded(uint256 boxId, uint8 rate);
    // =====================================================================================

    // rate / 1000 = %
    /**
     * @dev The official service fee rate
     */
    uint8 internal _serviceFeeRate;

    /**
     * @dev Slippage protection:
     * when swapping, this slippage protection will be applied
     */
    uint8 internal _slippageProtection;

    // =====================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
        _serviceFeeRate = 30; // 30
        _slippageProtection = 10; // 10
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

    /**
     * @dev Set slippage protection
     * @param slippageProtection_ The slippage protection rate
     * Can be set to 0-100
     */
    function setSlippageProtection(
        uint8 slippageProtection_
    ) external onlyAdminDAO {
        if (slippageProtection_ > 100) revert InvalidRate();
        _slippageProtection = slippageProtection_;
    }

    // ==========================================================================================================
    //                                         view get fee rate
    // ==========================================================================================================

    function serviceFeeRate() external view returns (uint8) {
        return _serviceFeeRate;
    }

    function slippageProtection() external view returns (uint8) {
        return _slippageProtection;
    }
}
