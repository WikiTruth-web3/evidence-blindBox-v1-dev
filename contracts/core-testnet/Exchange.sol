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

import {Exchange02} from "./base/Exchange02.sol";

/**
 *  @notice Exchange contract
 *  Implement basic TruthBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange is Exchange02 {
    // ========================================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) Exchange02(addrManager_, trustedForwarder_) {}

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

    /**
     * @notice Buy function, the buyer needs to pay
     * @param boxId_ Box ID
     * Need to check: status、buyer.
     * Buy will modify: buyer、status、refundRequestDeadline.
     * Bid also needs to calculate, and pay: payAmount
     */
    function buy(uint256 boxId_) external {
        ITruthBox truthBox = TRUTH_BOX;

        // _checkStatus(boxId_, Status.Selling);
        if (truthBox.getStatus(boxId_) != Status.Selling)
            revert InvalidStatus();

        truthBox.setStatus(boxId_, Status.Paid);

        address sender = _msgSender();

        uint256 userId = USER_MANAGER.getUserId(sender);
        _boxExchengData[boxId_]._buyer = sender;

        // Buy operation, should directly set the deadline for applying for refund
        _setRefundRequestDeadline(boxId_, block.timestamp);

        uint256 payAmount = truthBox.getPrice(boxId_);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount);

        emit BoxPurchased(boxId_, userId);
    }

    /**
     * @notice Bid function, the bidder needs to pay a higher price to get the bid qualification
     * @param boxId_ Box ID
     * Need to check: deadline、status、buyer.
     * Bid will modify: buyer、price、deadline.
     * Bid also needs to calculate, and pay: payAmount
     */
    function bid(uint256 boxId_) external {
        address sender = _msgSender();
        if (sender == _buyerOf(boxId_)) revert InvalidCaller();

        uint256 price = _bid(boxId_);

        uint256 payAmount = _calcPayMoney(boxId_, sender, price);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount); // need approve to FUND_MANAGER。

        _boxExchengData[boxId_]._buyer = sender;

        uint256 userId = USER_MANAGER.getUserId(sender);
        emit BidPlaced(boxId_, userId);
    }

    /**
     * @notice Calculate the pay amount
     * @param boxId_ Box ID
     * @param siweToken_ The siwe token of the user
     * @return The pay amount
     */
    function calcPayMoney(
        uint256 boxId_,
        bytes memory siweToken_
    ) public view returns (uint256) {
        // Use SiweContext get sender
        address sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        uint256 price = TRUTH_BOX.getPrice(boxId_);

        return _calcPayMoney(boxId_, sender, price);
    }

    // ========================================================================================================
    //                                           Refund function
    // ========================================================================================================

    /**
     * @notice Request refund function, after requesting refund, the box status becomes Refunding
     * Need to check: status、deadline.
     * Request refund will modify: status、refundReviewDeadline.
     * Request refund also needs to set the status of TRUTH_BOX to Published
     */
    function requestRefund(uint256 boxId_) external {
        // _checkStatus(boxId_, Status.Paid);
        ITruthBox truthBox = TRUTH_BOX;
        // canRequestRefund?
        if (truthBox.getStatus(boxId_) != Status.Paid) revert InvalidStatus();
        // erc2771 - _msgSender() is the real caller
        if (_msgSender() != _buyerOf(boxId_)) revert NotBuyer();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        if (isInRequestRefundDeadline(boxId_)) {
            uint256 deadline = block.timestamp + _refundReviewPeriod;
            _boxExchengData[boxId_]._refundReviewDeadline = deadline;
            truthBox.setStatus(boxId_, Status.Refunding);

            emit ReviewDeadlineChanged(boxId_, deadline);
        } else {
            truthBox.setStatus(boxId_, Status.Delaying);
            FUND_MANAGER.allocationRewards(boxId_);
        }
    }

    /**
     * @notice Cancel refund function, after canceling refund, the box status becomes Sold
     */
    function cancelRefund(uint256 boxId_) external {
        // erc2771 - _msgSender() is the real caller
        if (_msgSender() != _buyerOf(boxId_)) revert NotBuyer();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        // _checkStatus(boxId_, Status.Refunding);
        ITruthBox truthBox = TRUTH_BOX;
        if (truthBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();
        truthBox.setStatus(boxId_, Status.Delaying);
        FUND_MANAGER.allocationRewards(boxId_);
    }

    /**
     * @notice Agree refund function, after agreeing refund, the box status becomes Sold
     * Need to check: status、deadline.
     * Agree refund will modify: status、refundReviewDeadline.
     * Agree refund also needs to set the status of TRUTH_BOX to Published
     */
    function agreeRefund(uint256 boxId_) external {
        // _checkStatus(boxId_, Status.Refunding);
        ITruthBox truthBox = TRUTH_BOX;

        // canAgree?
        if (truthBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();

        // erc2771 - _msgSender() is the real caller
        if (isInReviewDeadline(boxId_)) {
            // Check role: minter、DAO
            if (
                _msgSender() != truthBox.minterOf(boxId_) &&
                msg.sender != ADDR_MANAGER.dao() // The dao must be a contract, so need not use _msgSender()
            ) {
                revert InvalidCaller();
            }
        }
        // If it exceeds the deadline, then it means anyone can call this function.
        _boxExchengData[boxId_]._refundPermit = true;
        truthBox.setStatus(boxId_, Status.Published);

        emit RefundPermitChanged(boxId_, true);
    }

    /**
     * @notice Refuse refund function, after refusing refund, the box status becomes Published!
     */
    function refuseRefund(uint256 boxId_) external {
        // _checkStatus(boxId_, Status.Refunding);
        ITruthBox truthBox = TRUTH_BOX;
        // canRefuse?
        if (truthBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();
        // According to whether it is within the review deadline, determine.
        if (isInReviewDeadline(boxId_)) {
            // Check role: DAO
            if (msg.sender != ADDR_MANAGER.dao()) revert InvalidCaller();
            truthBox.setStatus(boxId_, Status.Delaying);
            FUND_MANAGER.allocationRewards(boxId_);
        } else {
            _boxExchengData[boxId_]._refundPermit = true;
            truthBox.setStatus(boxId_, Status.Published);

            emit RefundPermitChanged(boxId_, true);
        }
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
        // _checkStatus(boxId_, Status.Paid);
        ITruthBox truthBox = TRUTH_BOX;
        // canComplete?
        if (truthBox.getStatus(boxId_) != Status.Paid) revert InvalidStatus();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        // erc2771
        address sender = _msgSender();

        if (sender != _buyerOf(boxId_)) {
            if (isInRequestRefundDeadline(boxId_)) revert DeadlineNotOver();
            if (sender != truthBox.minterOf(boxId_)) {
                _boxExchengData[boxId_]._completer = sender;
                uint256 userId = USER_MANAGER.getUserId(sender);
                emit CompleterAssigned(boxId_, userId);
            }
        }
        truthBox.setStatus(boxId_, Status.Delaying);
        FUND_MANAGER.allocationRewards(boxId_);
    }
}
