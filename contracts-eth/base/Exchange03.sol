// SPDX-License-Identifier: GPL-2.0-or-later
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.24;

import {IBlindBox, Status} from "@interfaces/eth/IBlindBox.sol";
import {Exchange02} from "./Exchange02.sol";
import {Main} from "@interfaces/IContracts.sol";

/**
 *  @notice Exchange03 contract
 *  Implement basic blindBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange03 is Exchange02 {
    // ========================================================================================================

    constructor(address addrManager_, address trustForwarder_) Exchange02(addrManager_, trustForwarder_) {}

    // ========================================================================================================
    //                                          Buying related functions
    // ========================================================================================================
    function _buy(uint256 boxId_) internal {
        IBlindBox blindBox = BLIND_BOX;
        if (blindBox.getStatus(boxId_) != Status.Selling) revert InvalidStatus();
        address sender = _msgSender();
        bytes32 userId = USER_MANAGER.getUserId(sender);

        uint256 payAmount = blindBox.getPrice(boxId_);


        blindBox.setStatus(boxId_, Status.Paid);

        _boxExchengData[boxId_]._buyerId = userId;
        _setRefundRequestDeadline(boxId_, block.timestamp);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount, userId);

        emit BoxPurchased(boxId_, userId);

    }

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

    function _bid(
        uint256 boxId_
    ) internal {
        address sender = _msgSender();
        bytes32 userId = USER_MANAGER.getUserId(sender);
        if (userId == _buyerIdOf(boxId_)) revert InvalidCaller();

        uint256 currentPrice = _bidPrice(boxId_);
        uint256 payAmount = _calcPayAmount(boxId_, userId, currentPrice);

        _boxExchengData[boxId_]._buyerId = userId;
        _setRefundRequestDeadline(boxId_, block.timestamp);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount, userId);

        emit BidPlaced(boxId_, userId);
    }

    /**
     * @notice Bid function, the bidder needs to pay a higher price to get the bid qualification
     * @param boxId_ Box ID
     * Need to check: deadline、status、buyer.
     * Bid will modify: buyer、price、deadline.
     * Bid also needs to calculate, and pay: payAmount
     */

    function _calcPayAmount(
        uint256 boxId_,
        bytes32 userId_,
        uint256 price_
    ) internal view returns (uint256) {
        uint256 balance = FUND_MANAGER.orderAmounts(
            boxId_,
            userId_
        );
        uint256 payAmount = price_ - balance;
        return payAmount;
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
        // erc2771 - _msgSender() is the real caller
        bytes32 userId = USER_MANAGER.getUserId(_msgSender());
        if (userId != _buyerIdOf(boxId_)) revert NotBuyer();

        if (_isInRequestRefundDeadline(boxId_)) {
            uint256 deadline = block.timestamp + _refundReviewPeriod;
            _boxExchengData[boxId_]._refundReviewDeadline = deadline;

            blindBox.setStatus(boxId_, Status.Refunding);
            emit ReviewDeadlineChanged(boxId_, deadline);
        } else {
            blindBox.setStatus(boxId_, Status.Delaying);
            FUND_MANAGER.allocationRewards(boxId_);
        }
    }

    /**
     * @notice Cancel refund function, after canceling refund, the box status becomes Sold
     */
    function _cancelRefund(uint256 boxId_) internal {
        // erc2771 - _msgSender() is the real caller
        bytes32 userId = USER_MANAGER.getUserId(_msgSender());
        if (userId != _buyerIdOf(boxId_)) revert NotBuyer();

        IBlindBox blindBox = BLIND_BOX;
        if (blindBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();

        blindBox.setStatus(boxId_, Status.Delaying);
        FUND_MANAGER.allocationRewards(boxId_);
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
            // erc2771 - _msgSender() is the real caller
            address sender = _msgSender();
            // Check role: minter、DAO
            bytes32 userId = USER_MANAGER.getUserId(sender);
            if (
                userId != blindBox.minterIdOf(boxId_) &&
                sender != ADDR_MANAGER.getMainContract(Main.Dao) // The dao must be a contract, so need not use _msgSender()
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

        if (_msgSender() != ADDR_MANAGER.getMainContract(Main.Dao)) revert NotDAO();
        // canRefuse?
        if (blindBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();
        // According to whether it is within the review deadline, determine.
        if (_isInReviewDeadline(boxId_)) {
            // Check role: DAO
            blindBox.setStatus(boxId_, Status.Delaying);
            FUND_MANAGER.allocationRewards(boxId_);
        } else {
            _boxExchengData[boxId_]._refundPermit = true;
            blindBox.setStatus(boxId_, Status.Published);
            emit RefundPermitChanged(boxId_, true);
        }
    }

}
