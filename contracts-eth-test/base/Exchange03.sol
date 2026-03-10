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

import {Exchange02} from "./Exchange02.sol";

/**
 *  @notice Exchange03 contract
 *  Implement basic TruthBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange03 is Exchange02 {
    // ========================================================================================================

    constructor(address addrManager_) Exchange02(addrManager_) {}

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
    function _buy(uint256 boxId_) internal {
        ITruthBox truthBox = TRUTH_BOX;

        // _checkStatus(boxId_, Status.Selling);
        if (truthBox.getStatus(boxId_) != Status.Selling)
            revert InvalidStatus();

        truthBox.setStatus(boxId_, Status.Paid);

        address sender = msg.sender;

        uint256 userId = USER_MANAGER.getUserId(sender);
        _boxExchengData[boxId_]._buyerId = userId;

        // Buy operation, should directly set the deadline for applying for refund
        _setRefundRequestDeadline(boxId_, block.timestamp);

        uint256 payAmount = truthBox.getPrice(boxId_);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount, userId);

        emit BoxPurchased(boxId_, userId);
    }

    // =========================================================================================================
    //                                           finalize related functions
    // ========================================================================================================

    function _setRefundPermit(
        uint256 boxId_,
        bool permission_
    ) internal onlyProjectContract {
        _boxExchengData[boxId_]._refundPermit = permission_;
        emit RefundPermitChanged(boxId_, permission_);
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
    function _requestRefund(uint256 boxId_) internal {
        // _checkStatus(boxId_, Status.Paid);
        ITruthBox truthBox = TRUTH_BOX;
        // canRequestRefund?
        if (truthBox.getStatus(boxId_) != Status.Paid) revert InvalidStatus();
        // erc2771 - msg.sender is the real caller
        uint256 userId = USER_MANAGER.getUserId(msg.sender);
        if (userId != _buyerIdOf(boxId_)) revert NotBuyer();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        if (_isInRequestRefundDeadline(boxId_)) {
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
    function _cancelRefund(uint256 boxId_) internal {
        // erc2771 - msg.sender is the real caller
        uint256 userId = USER_MANAGER.getUserId(msg.sender);
        if (userId != _buyerIdOf(boxId_)) revert NotBuyer();
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
    function _agreeRefund(uint256 boxId_) internal {
        // _checkStatus(boxId_, Status.Refunding);
        ITruthBox truthBox = TRUTH_BOX;

        // canAgree?
        if (truthBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();

        if (_isInReviewDeadline(boxId_)) {
            // Check role: minter、DAO
            uint256 userId = USER_MANAGER.getUserId(msg.sender);
            if (
                // erc2771 - msg.sender is the real caller
                userId != truthBox.minterIdOf(boxId_) &&
                msg.sender != ADDR_MANAGER.dao() // The dao must be a contract, so need not use msg.sender
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
    function _refuseRefund(uint256 boxId_) internal {
        // _checkStatus(boxId_, Status.Refunding);
        ITruthBox truthBox = TRUTH_BOX;
        // canRefuse?
        if (truthBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();
        // According to whether it is within the review deadline, determine.
        if (_isInReviewDeadline(boxId_)) {
            // Check role: DAO
            if (msg.sender != ADDR_MANAGER.dao()) revert NotDAO();
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
    function _completeOrder(uint256 boxId_) internal {
        // _checkStatus(boxId_, Status.Paid);
        ITruthBox truthBox = TRUTH_BOX;
        // canComplete?
        if (truthBox.getStatus(boxId_) != Status.Paid) revert InvalidStatus();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        // erc2771
        address sender = msg.sender;
        uint256 userId = USER_MANAGER.getUserId(sender);

        if (userId != _buyerIdOf(boxId_)) {
            if (_isInRequestRefundDeadline(boxId_)) revert DeadlineNotOver();
            if (userId != truthBox.minterIdOf(boxId_)) {
                _boxExchengData[boxId_]._completerId = userId;
                emit CompleterAssigned(boxId_, userId);
            }
        }
        truthBox.setStatus(boxId_, Status.Delaying);
        FUND_MANAGER.allocationRewards(boxId_);
    }
}
