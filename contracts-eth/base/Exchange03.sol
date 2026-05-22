// SPDX-License-Identifier: GPL-2.0-or-later
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.24;

import {IBlindBox, Status} from "@interfaces/eth/IBlindBox.sol";
import {PaymentType} from "@interfaces/eth/IExchange.sol";

import {Exchange02} from "./Exchange02.sol";

/**
 *  @notice Exchange03 contract
 *  Implement basic blindBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange03 is Exchange02 {
    // ========================================================================================================

    constructor(address addrManager_) Exchange02(addrManager_) {}

    // ========================================================================================================
    //                                          Buying related functions
    // ========================================================================================================

    /**
     * @notice Bid function, the bidder needs to pay a higher price to get the bid资格
     * @param boxId_ Box ID
     */
    function _bidPrice(uint256 boxId_) internal returns (uint256) {
        IBlindBox BlindBox = BLIND_BOX;
        (Status status, uint256 price, ) = BlindBox.getBasicData(boxId_);

        // canBid?
        if (status != Status.Auctioning) revert InvalidStatus();

        uint256 newPrice = (price * _bidIncrementRate) / 100; // If bidIncrementRate is 110, then it is 110%

        BlindBox.setBasicData(
            boxId_,
            newPrice,
            Status.Auctioning,
            block.timestamp + 30 days
        );

        return price;
    }

    // ========================================================================================================
    //                                           Refund function
    // ========================================================================================================

    /**
     * @notice Request refund function, after requesting refund, the box status becomes Refunding
     * Need to check: status、deadline.
     * Request refund will modify: status、refundReviewDeadline.
     * Request refund also needs to set the status of BLIND_BOX to Published
     */
    function _requestRefund(uint256 boxId_) internal {
        IBlindBox blindBox = BLIND_BOX;
        // canRequestRefund?
        if (blindBox.getStatus(boxId_) != Status.Paid) revert InvalidStatus();
        // erc2771 - msg.sender is the real caller
        bytes32 userId = USER_MANAGER.getUserId(msg.sender);
        if (userId != _buyerIdOf(boxId_)) revert NotBuyer();

        if (_isInRequestRefundDeadline(boxId_)) {
            uint256 deadline = block.timestamp + _refundReviewPeriod;
            _boxExchengData[boxId_]._refundReviewDeadline = deadline;

            blindBox.setStatus(boxId_, Status.Refunding);
            emit ReviewDeadlineChanged(boxId_, deadline);
        } else {
            blindBox.setStatus(boxId_, Status.Delaying);
            _processAllocation(boxId_);
        }
    }

    /**
     * @notice Cancel refund function, after canceling refund, the box status becomes Sold
     */
    function _cancelRefund(uint256 boxId_) internal {
        // erc2771 - msg.sender is the real caller
        bytes32 userId = USER_MANAGER.getUserId(msg.sender);
        if (userId != _buyerIdOf(boxId_)) revert NotBuyer();

        IBlindBox blindBox = BLIND_BOX;
        if (blindBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();

        blindBox.setStatus(boxId_, Status.Delaying);
        _processAllocation(boxId_);
    }

    /**
     * @notice Agree refund function, after agreeing refund, the box status becomes Sold
     * Need to check: status、deadline.
     * Agree refund will modify: status、refundReviewDeadline.
     * Agree refund also needs to set the status of BLIND_BOX to Published
     */
    function _agreeRefund(uint256 boxId_) internal {
        IBlindBox blindBox = BLIND_BOX;

        // canAgree?
        if (blindBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();

        if (_isInReviewDeadline(boxId_)) {
            // Check role: minter、DAO
            bytes32 userId = USER_MANAGER.getUserId(msg.sender);
            if (
                // erc2771 - msg.sender is the real caller
                userId != blindBox.minterIdOf(boxId_) &&
                msg.sender != ADDR_MANAGER.dao() // The dao must be a contract, so need not use msg.sender
            ) {
                revert InvalidCaller();
            }
        }
        // If it exceeds the deadline, then it means anyone can call this function.
        _boxExchengData[boxId_]._refundPermit = true;
        blindBox.setStatus(boxId_, Status.Published);

        emit RefundPermitChanged(boxId_, true);

    }

    /**
     * @notice Refuse refund function, after refusing refund, the box status becomes Published!
     */
    function _refuseRefund(uint256 boxId_) internal {
        IBlindBox blindBox = BLIND_BOX;
        // canRefuse?
        if (blindBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();
        // According to whether it is within the review deadline, determine.
        if (_isInReviewDeadline(boxId_)) {
            // Check role: DAO
            if (msg.sender != ADDR_MANAGER.dao()) revert NotDAO();
            blindBox.setStatus(boxId_, Status.Delaying);
            _processAllocation(boxId_);
        } else {
            _boxExchengData[boxId_]._refundPermit = true;
            blindBox.setStatus(boxId_, Status.Published);

            emit RefundPermitChanged(boxId_, true);
        }
    }

}
