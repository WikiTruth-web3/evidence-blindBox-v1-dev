// SPDX-License-Identifier: GPL-2.0-or-later
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.24;

import {IBlindBox, Status} from "@interfaces/eth/IBlindBox.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";
import {Exchange03} from "./base/Exchange03.sol";
import {Main} from "@interfaces/IContracts.sol";

/**
 *  @notice Exchange contract
 *  Implement basic BlindBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange is Exchange03, IExchange {
    // ========================================================================================================

    constructor(address addrManager_) Exchange03(addrManager_) {}

    // ==========================================================================================================

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setContracts() external onlyManager {
        _setContracts(Main.Exchange);
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
            365 days
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
            30 days
        );
    }
    // ========================================================================================================
    //                                          Buying related functions
    // ========================================================================================================

    function buy(
        uint256 boxId_
    ) external {
        _buy(boxId_);
    }

    function bid(
        uint256 boxId_
    ) external {
        _bid(boxId_);
    }

    function calcPayAmount(
        uint256 boxId_
    ) public view returns (uint256) {
        // Use SiweContext get sender
        // address sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        address sender = msg.sender;
        bytes32 userId = USER_MANAGER.getUserId(sender);
        uint256 price = BLIND_BOX.getPrice(boxId_);

        return _calcPayAmount(boxId_, userId, price);
    }

    // ========================================================================================================
    //                                           Refund function
    // ========================================================================================================

    function setRefundPermitTrue(
        uint256 boxId_
    ) external onlyProjectContract {
        _setRefundPermitTrue(boxId_);
    }

    function requestRefund(uint256 boxId_) external {
        _requestRefund(boxId_);
    }

    /**
     * @notice Cancel refund function, after canceling refund, the box status becomes Sold
     */
    function cancelRefund(uint256 boxId_) external {
        _cancelRefund(boxId_);
    }

    function agreeRefund(uint256 boxId_) external {
        _agreeRefund(boxId_);
    }

    /**
     * @notice Refuse refund function, after refusing refund, the box status becomes Published!
     */
    function refuseRefund(uint256 boxId_) external {
        _refuseRefund(boxId_);
    }

    // ========================================================================================================
    //                                           Getter function
    // ========================================================================================================

    /**
     * @notice Get buyer address
     * @param boxId_ Box ID
     * @return Buyer address
     */
    function buyerIdOf(uint256 boxId_) external view returns (bytes32) {
        return _buyerIdOf(boxId_);
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
