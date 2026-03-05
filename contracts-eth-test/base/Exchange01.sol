// SPDX-License-Identifier: GPL-2.0-or-later
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

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

// import "@openzeppelin/contracts/utils/Context.sol";

// import {IUserManager} from "@marketplace-v1/interfaces/IUserManager.sol";
// import {ITruthBox} from "@marketplace-v1/interfaces/ITruthBox.sol";
// import {IFundManager} from "@marketplace-v1/interfaces/IFundManager.sol";
// import {IExchange} from "@marketplace-v1/interfaces/IExchange.sol";
// import {IAddressManager} from "@marketplace-v1/interfaces/IAddressManager.sol";

import {ModifierV2} from "../modifier/ModifierV2.sol";

/**
 *  @title Exchange01
 *  @dev This contract is used to manage the exchange
 *  @dev Inherits ModifierV2 to support modifiers
 */

contract Exchange01 is ModifierV2 {
    uint256 internal _refundRequestPeriod;
    uint256 internal _refundReviewPeriod;

    uint8 internal _bidIncrementRate;

    // ========================================================================================================

    constructor(address addrManager_) ModifierV2(addrManager_) {
        _bidIncrementRate = 110;
        _refundRequestPeriod = 7 days;
        _refundReviewPeriod = 15 days;
    }

    // =====================================================================================
    //                                      Basic Parameter Settings
    // =====================================================================================

    // 7~15  || 1~7
    function setRefundRequestPeriod(uint256 period_) external onlyDAO {
        if (period_ < 7 days || period_ > 15 days) revert InvalidPeriod();
        _refundRequestPeriod = period_;
    }
    // 15~30  || 1~7
    function setRefundReviewPeriod(uint256 period_) external onlyDAO {
        if (period_ < 15 days || period_ > 60 days) revert InvalidPeriod();
        _refundReviewPeriod = period_;
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
    function refundReviewPeriod() external view returns (uint256) {
        return _refundReviewPeriod;
    }
    function bidIncrementRate() external view returns (uint8) {
        return _bidIncrementRate;
    }
}
