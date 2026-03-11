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

import {ITruthBox, Status} from "@marketplace-v1/interfaces-eth/ITruthBox.sol";
import {IExchange} from "@marketplace-v1/interfaces-eth/IExchange.sol";
import {Exchange03} from "./base/Exchange03.sol";
import {CoreContracts} from "@marketplace-v1/interfaces/IContracts.sol";

/**
 *  @notice Exchange contract
 *  Implement basic TruthBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
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

    /**
     * @notice Buy function, the buyer needs to pay
     * @param boxId_ Box ID
     * Need to check: status、buyer.
     * Buy will modify: buyer、status、refundRequestDeadline.
     * Bid also needs to calculate, and pay: payAmount
     */
    function buy(uint256 boxId_) external {
        _buy(boxId_);
    }

    /**
     * @notice Bid function, the bidder needs to pay a higher price to get the bid qualification
     * @param boxId_ Box ID
     * Need to check: deadline、status、buyer.
     * Bid will modify: buyer、price、deadline.
     * Bid also needs to calculate, and pay: payAmount
     */
    function bid(uint256 boxId_) external {
        _bid(boxId_);
    }

    /**
     * @notice Calculate the pay amount
     * @param boxId_ Box ID
     * @return The pay amount
     */
    function calcPayMoney(uint256 boxId_) public view returns (uint256) {
        uint256 price = TRUTH_BOX.getPrice(boxId_);
        bytes32 userId = USER_MANAGER.getUserId(msg.sender);

        return _calcPayMoney(boxId_, userId, price);
    }

    // ========================================================================================================
    //                                           Refund function
    // ========================================================================================================

    function setRefundPermit(
        uint256 boxId_,
        bool permission_
    ) external onlyProjectContract {
        _setRefundPermit(boxId_, permission_);
    }
    /**
     * @notice Request refund function, after requesting refund, the box status becomes Refunding
     * Need to check: status、deadline.
     * Request refund will modify: status、refundReviewDeadline.
     * Request refund also needs to set the status of TRUTH_BOX to Published
     */
    function requestRefund(uint256 boxId_) external {
        _requestRefund(boxId_);
    }

    /**
     * @notice Cancel refund function, after canceling refund, the box status becomes Sold
     */
    function cancelRefund(uint256 boxId_) external {
        _cancelRefund(boxId_);
    }

    /**
     * @notice Agree refund function, after agreeing refund, the box status becomes Sold
     * Need to check: status、deadline.
     * Agree refund will modify: status、refundReviewDeadline.
     * Agree refund also needs to set the status of TRUTH_BOX to Published
     */
    function agreeRefund(uint256 boxId_) external {
        _agreeRefund(boxId_);
    }

    /**
     * @notice Refuse refund function, after refusing refund, the box status becomes Published!
     */
    function refuseRefund(uint256 boxId_) external {
        _refuseRefund(boxId_);
    }

    // =========================================================================================================
    //                                           finalize related functions
    // ========================================================================================================

    /**
     * @notice Complete order function, after completing order, the box status becomes Sold
     * Need to check: refundPermit.
     * Complete order will modify: status、completer.
     * Complete order also needs to set the status of TRUTH_BOX to Delaying
     * Complete order also needs to set refundRequestDeadline.
     */
    function completeOrder(uint256 boxId_) external {
        _completeOrder(boxId_);
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

    /* NOTE If the _seller is address(0),
     * it means that the _seller is the minter
     */
    function sellerIdOf(uint256 boxId_) external view returns (bytes32) {
        return _sellerIdOf(boxId_);
    }

    /**
     * @notice Get completer address
     * @param boxId_ Box ID
     * @return Completer address
     */
    function completerIdOf(uint256 boxId_) external view returns (bytes32) {
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
