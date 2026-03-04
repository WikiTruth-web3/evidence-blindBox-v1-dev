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

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "../utils/Pausable.sol";

import {ModifierV2} from "../modifier/ModifierV2.sol";

/**
 * @title FundManagerBase
 * @dev Fund management contract that supports multiple tokens
 * v1.6 upgraded version of FundManager, extending existing FundManager to support multi-token transactions
 */

contract FundManagerBase is ModifierV2, ReentrancyGuard, Pausable {
    error EnforcedPause();

    event BuyerRefundRateAdded(uint256 boxId, uint8 rate);
    event DaoFeeRateAdded(uint256 boxId, uint8 rate);
    // =====================================================================================

    // rate / 1000 = %
    /**
     * @dev The official service fee rate
     */
    uint8 internal _serviceFeeRate;
    /**
     * @dev The ecosystem participant reward rate
     */
    uint8 internal _helperRewardRate;

    /**
     * @dev Extra fee:
     * when using non-settlement tokens, this fee will be incurred
     */
    uint8 internal _extraFeeRate;

    /**
     * @dev Slippage protection:
     * when swapping, this slippage protection will be applied
     */
    uint8 internal _slippageProtection;

    // =====================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
        _serviceFeeRate = 30; // 30
        _helperRewardRate = 10; // 10
        _extraFeeRate = 10; // 10
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
     * @dev Set helper reward rate
     * @param Rate_ The helper reward rate
     * Can be set to 0-30
     */
    function setHelperRewardRate(uint8 Rate_) external onlyDAO {
        if (Rate_ > 30) revert InvalidRate();
        _helperRewardRate = Rate_;
    }

    /**
     * @dev Set extra fee rate
     * @param Rate_ The extra fee rate
     * Can be set to 0-20
     */
    function setExtraFeeRate(uint8 Rate_) external onlyDAO {
        if (Rate_ > 20) revert InvalidRate();
        _extraFeeRate = Rate_;
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

    // change name
    function helperRewardRate() external view returns (uint8) {
        return _helperRewardRate;
    }

    function serviceFeeRate() external view returns (uint8) {
        return _serviceFeeRate;
    }

    function extraFeeRate() external view returns (uint8) {
        return _extraFeeRate;
    }

    function slippageProtection() external view returns (uint8) {
        return _slippageProtection;
    }
}
