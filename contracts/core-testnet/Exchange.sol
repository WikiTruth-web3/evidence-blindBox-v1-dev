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

import {ITruthBox, Status} from "@marketplace-v1/interfaces/ITruthBox.sol";
import {IExchange} from "@marketplace-v1/interfaces/IExchange.sol";
import {Exchange03} from "./base/Exchange03.sol";
import {CoreContracts} from "@marketplace-v1/interfaces/IContracts.sol";

/**
 *  @notice Exchange contract
 *  Implement basic TruthBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange is Exchange03, IExchange {
    // ========================================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) Exchange03(addrManager_, trustedForwarder_) {}

    // ==========================================================================================================

    function setAddress() external onlyManager {
        _setAddress(CoreContracts.Exchange);
    }

    // ========================================================================================================
    //                                          Listing related functions
    // ========================================================================================================

    function sell(
        uint256 boxId_,
        address acceptedToken_,
        uint256 price_
    ) external {
        // NOTE: 365----15
        _setBoxListedArgs(
            boxId_,
            acceptedToken_,
            price_,
            Status.Selling,
            15 days
        );
    }

    function auction(
        uint256 boxId_,
        address acceptedToken_,
        uint256 price_
    ) external {
        // NOTE: 30 days----3 days
        _setBoxListedArgs(
            boxId_,
            acceptedToken_,
            price_,
            Status.Auctioning,
            3 days
        );
    }

    // ========================================================================================================
    //                                          Buying related functions
    // ========================================================================================================

    function buy(uint256 boxId_) external {
        _buy(boxId_);
    }

    function bid(uint256 boxId_) external {
        _bid(boxId_);
    }

    function calcPayMoney(
        uint256 boxId_,
        bytes memory siweToken_
    ) public view returns (uint256) {
        // Use SiweContext get sender
        address sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        uint256 userId = USER_MANAGER.viewUserId(sender);
        uint256 price = TRUTH_BOX.getPrice(boxId_);

        return _calcPayMoney(boxId_, userId, price);
    }

    // ========================================================================================================
    //                                           Refund function
    // ========================================================================================================

    function setRefundPermit(uint256 boxId_, bool permission_) external {
        _setRefundPermit(boxId_, permission_);
    }

    function requestRefund(uint256 boxId_) external {
        _requestRefund(boxId_);
    }

    function cancelRefund(uint256 boxId_) external {
        _cancelRefund(boxId_);
    }

    function agreeRefund(uint256 boxId_) external {
        _agreeRefund(boxId_);
    }

    function refuseRefund(uint256 boxId_) external {
        _refuseRefund(boxId_);
    }

    // =========================================================================================================
    //                                           finalize related functions
    // ========================================================================================================

    function completeOrder(uint256 boxId_) external {
        _completeOrder(boxId_);
    }

    // ========================================================================================================
    //                                           Getter function
    // ========================================================================================================

    function buyerIdOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (uint256) {
        return _buyerIdOf(boxId_);
    }

    function sellerIdOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (uint256) {
        return _sellerIdOf(boxId_);
    }

    function completerIdOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (uint256) {
        return _completerIdOf(boxId_);
    }

    // ===========================
    function acceptedToken(uint256 boxId_) external view returns (address) {
        return _acceptedToken(boxId_);
    }

    // ===========================

    function refundPermit(uint256 boxId_) external view returns (bool) {
        return _refundPermit(boxId_);
    }

    function refundRequestDeadline(
        uint256 boxId_
    ) external view returns (uint256) {
        return _refundRequestDeadline(boxId_);
    }

    function refundReviewDeadline(
        uint256 boxId_
    ) external view returns (uint256) {
        return _refundReviewDeadline(boxId_);
    }

    function isInRequestRefundDeadline(
        uint256 boxId_
    ) external view returns (bool) {
        return _isInRequestRefundDeadline(boxId_);
    }

    function isInReviewDeadline(uint256 boxId_) external view returns (bool) {
        return _isInReviewDeadline(boxId_);
    }
}
