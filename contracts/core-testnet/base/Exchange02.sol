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

import {CoreContracts} from "@marketplace-v1/interfaces/IContracts.sol";

/**
 *  @notice Exchange02 contract
 *  Implement basic TruthBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange02 is Exchange01, ExchangeEvents, ERC2771Context, SiweContext {
    error RefundPermitTrue();

    // =======================================================================================================

    struct BoxExchengData {
        address _acceptedToken; // If address(0), then it means support settlementToken
        address _seller; // If address(0), then it means by minter sell
        address _buyer;
        address _completer;
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

    // ==========================================================================================================
    //                                          Override Functions
    // ==========================================================================================================

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external onlyManager {
        _setAddress(CoreContracts.Exchange);
    }

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
    function isInRequestRefundDeadline(
        uint256 boxId_
    ) public view returns (bool) {
        _checkStatus(boxId_, Status.Paid);

        if (_boxExchengData[boxId_]._refundRequestDeadline < block.timestamp)
            return false;
        return true;
    }

    function isInReviewDeadline(uint256 boxId_) public view returns (bool) {
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
        address token = ADDR_MANAGER.settlementToken();

        if (sender != truthBox.minterOf(boxId_)) {
            // others sell
            if (truthBox.getDeadline(boxId_) >= block.timestamp)
                revert DeadlineNotOver();
            _boxExchengData[boxId_]._seller = sender;

            // if the _seller is not the minter, they can't set the price
            price_ = 0;
        } else {
            // NOTE minter sell
            // if the acceptedToken_ is not settlement, set it as acceptedToken
            if (acceptedToken_ != token) {
                if (!ADDR_MANAGER.isTokenSupported(acceptedToken_)) return;

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
    function _bid(uint256 boxId_) internal returns (uint256) {
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

    function _calcPayMoney(
        uint256 boxId_,
        address buyer_,
        uint256 price_
    ) internal view returns (uint256) {
        uint256 balance = FUND_MANAGER.orderAmounts(boxId_, buyer_);
        uint256 amount = price_ - balance;
        return amount;
    }

    // =========================================================================================================
    //                                           finalize related functions
    // ========================================================================================================

    // ========================================================================================================

    function setRefundPermit(
        uint256 boxId_,
        bool permission_
    ) external onlyProjectContract {
        _boxExchengData[boxId_]._refundPermit = permission_;
        emit RefundPermitChanged(boxId_, permission_);
    }

    // ========================================================================================================
    //                                           Getter function
    // ========================================================================================================

    /**
     * @notice Get buyer address
     * @param boxId_ Box ID
     * @return Buyer address
     */
    function buyerOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (address) {
        return _buyerOf(boxId_);
    }

    /* NOTE If the _seller is address(0),
     * it means that the _seller is the minter
     */
    function sellerOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (address) {
        return _boxExchengData[boxId_]._seller;
    }

    /**
     * @notice Get completer address
     * @param boxId_ Box ID
     * @return Completer address
     */
    function completerOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (address) {
        return _boxExchengData[boxId_]._completer;
    }

    function _buyerOf(uint256 boxId_) internal view returns (address) {
        return _boxExchengData[boxId_]._buyer;
    }

    function _refundPermit(uint256 boxId_) internal view returns (bool) {
        return _boxExchengData[boxId_]._refundPermit;
    }

    function refundPermit(uint256 boxId_) external view returns (bool) {
        return _refundPermit(boxId_);
    }

    /**
     * @notice Get supported token
     */
    function acceptedToken(uint256 boxId_) external view returns (address) {
        address token = _boxExchengData[boxId_]._acceptedToken;
        if (token == address(0)) return ADDR_MANAGER.settlementToken();
        return token;
    }

    function refundReviewDeadline(
        uint256 boxId_
    ) external view returns (uint256) {
        return _boxExchengData[boxId_]._refundReviewDeadline;
    }

    function refundRequestDeadline(
        uint256 boxId_
    ) external view returns (uint256) {
        return _boxExchengData[boxId_]._refundRequestDeadline;
    }

    // -------------------------------------------------------------------
}
