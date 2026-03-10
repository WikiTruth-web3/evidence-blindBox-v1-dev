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

import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import {ITruthBox, Status} from "@marketplace-v1/interfaces/ITruthBox.sol";
import {ExchangeEvents} from "@marketplace-v1/interfaces/IExchange.sol";
import {Exchange01} from "./Exchange01.sol";
import {SiweContext} from "@siwe/SiweContext.sol";

/**
 *  @notice Exchange02 contract
 *  Implement basic TruthBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange02 is Exchange01, ExchangeEvents, ERC2771Context, SiweContext {
    // =======================================================================================================

    struct BoxExchengData {
        address _acceptedToken; // If address(0), then it means support settlementToken
        uint256 _sellerId; // If 0, then it means by minter sell
        uint256 _buyerId;
        uint256 _completerId;
        uint256 _refundRequestDeadline;
        uint256 _refundReviewDeadline;
        bool _refundPermit;
    }

    mapping(uint256 boxId => BoxExchengData data) internal _boxExchengData;

    // ========================================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) Exchange01(addrManager_) ERC2771Context(trustedForwarder_) {}

    // ========================================================================================================
    //                                           Checker functions
    // ========================================================================================================

    /**
     * @notice Read box status
     * @param boxId_ Box ID
     * If the box status is Auctioning, and the deadline is over, then it is directly Paid.
     */
    function _checkStatus(uint256 boxId_, Status status_) internal view {
        if (TRUTH_BOX.getStatus(boxId_) != status_) revert InvalidStatus();
    }

    // Check the refund timestamp. Within the refund time,
    // you can apply for a refund (set to refunding mode),
    function _isInRequestRefundDeadline(
        uint256 boxId_
    ) internal view returns (bool) {
        _checkStatus(boxId_, Status.Paid);

        if (_boxExchengData[boxId_]._refundRequestDeadline < block.timestamp)
            return false;
        return true;
    }

    function _isInReviewDeadline(uint256 boxId_) internal view returns (bool) {
        _checkStatus(boxId_, Status.Refunding);
        if (_boxExchengData[boxId_]._refundReviewDeadline < block.timestamp)
            return false;
        return true;
    }

    // ========================================================================================================
    //                                            Setter functions
    //========================================================================================================

    function _setBoxListedArgs(
        uint256 boxId_,
        address acceptedToken_,
        uint256 price_,
        Status status_,
        uint256 seconds_
    ) internal {
        ITruthBox truthBox = TRUTH_BOX;
        if (truthBox.getStatus(boxId_) != Status.Storing)
            revert InvalidStatus();
        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();

        uint256 userId = USER_MANAGER.getUserId(sender);
        address token;

        if (userId != truthBox.minterIdOf(boxId_)) {
            // others sell
            if (truthBox.getDeadline(boxId_) >= block.timestamp) {
                revert DeadlineNotOver();
            }
            _boxExchengData[boxId_]._sellerId = userId;

            // if the _seller is not the minter, they can't set the price
            price_ = 0;
        } else {
            // NOTE minter sell
            if (
                acceptedToken_ != address(0) &&
                acceptedToken_ != ADDR_MANAGER.settlementToken()
            ) {
                if (!ADDR_MANAGER.isTokenSupported(acceptedToken_)) {
                    revert TokenNotSupported();
                }
                _boxExchengData[boxId_]._acceptedToken = acceptedToken_;
                token = acceptedToken_;
            }
        }
        truthBox.setBasicData(
            boxId_,
            price_,
            status_,
            block.timestamp + seconds_
        );

        emit BoxListed(boxId_, userId, token);
    }

    function _setRefundRequestDeadline(
        uint256 boxId_,
        uint256 timestamp
    ) internal {
        uint256 deadline = timestamp + _refundRequestPeriod;
        _boxExchengData[boxId_]._refundRequestDeadline = deadline;

        emit RequestDeadlineChanged(boxId_, deadline);
    }

    // ========================================================================================================
    //                                          Buying related functions
    // ========================================================================================================
    /**
     * @notice Bid function, the bidder needs to pay a higher price to get the bid资格
     * @param boxId_ Box ID
     */
    function _bidPrice(uint256 boxId_) internal returns (uint256) {
        ITruthBox truthBox = TRUTH_BOX;
        (Status status, uint256 price, uint256 deadline) = truthBox
            .getBasicData(boxId_);

        // canBid?
        if (deadline < block.timestamp) revert DeadlineIsOver();
        if (status != Status.Auctioning) revert InvalidStatus();

        // NOTE: 30 days----3 days
        _setRefundRequestDeadline(boxId_, block.timestamp + 3 days);
        uint256 newPrice = (price * _bidIncrementRate) / 100; // If bidIncrementRate is 110, then it is 110%

        truthBox.setBasicData(
            boxId_,
            newPrice,
            Status.Auctioning,
            block.timestamp + 3 days
        );

        return price;
    }

    /**
     * @notice Bid function, the bidder needs to pay a higher price to get the bid qualification
     * @param boxId_ Box ID
     * Need to check: deadline、status、buyer.
     * Bid will modify: buyer、price、deadline.
     * Bid also needs to calculate, and pay: payAmount
     */
    function _bid(uint256 boxId_) internal {
        address sender = _msgSender();
        uint256 userId = USER_MANAGER.getUserId(sender);
        if (userId == _buyerIdOf(boxId_)) revert NotBuyer();

        uint256 price = _bidPrice(boxId_);

        uint256 payAmount = _calcPayMoney(boxId_, userId, price);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount, userId); // need approve to FUND_MANAGER。

        _boxExchengData[boxId_]._buyerId = userId;

        emit BidPlaced(boxId_, userId);
    }

    function _calcPayMoney(
        uint256 boxId_,
        uint256 userId_,
        uint256 price_
    ) internal view returns (uint256) {
        uint256 balance = FUND_MANAGER.orderAmountsProject(boxId_, userId_);
        uint256 amount = price_ - balance;
        return amount;
    }

    // ========================================================================================================
    //                                           Getter function
    // ========================================================================================================

    function _buyerIdOf(uint256 boxId_) internal view returns (uint256) {
        return _boxExchengData[boxId_]._buyerId;
    }

    function _sellerIdOf(uint256 boxId_) internal view returns (uint256) {
        return _boxExchengData[boxId_]._sellerId;
    }

    function _completerIdOf(uint256 boxId_) internal view returns (uint256) {
        return _boxExchengData[boxId_]._completerId;
    }

    function _refundPermit(uint256 boxId_) internal view returns (bool) {
        return _boxExchengData[boxId_]._refundPermit;
    }

    /**
     * @notice Get supported token
     */
    function _acceptedToken(uint256 boxId_) internal view returns (address) {
        address token = _boxExchengData[boxId_]._acceptedToken;
        if (token == address(0)) return ADDR_MANAGER.settlementToken();
        return token;
    }

    function _refundReviewDeadline(
        uint256 boxId_
    ) internal view returns (uint256) {
        return _boxExchengData[boxId_]._refundReviewDeadline;
    }

    function _refundRequestDeadline(
        uint256 boxId_
    ) internal view returns (uint256) {
        return _boxExchengData[boxId_]._refundRequestDeadline;
    }

    // -------------------------------------------------------------------
}
