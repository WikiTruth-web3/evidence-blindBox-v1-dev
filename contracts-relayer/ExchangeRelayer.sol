// SPDX-License-Identifier: GPL-2.0-or-later

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

import {ITruthBox, Status} from "@wikitruth-v1/interfaces/ITruthBox.sol";
import {IExchange} from "@wikitruth-v1/interfaces/IExchange.sol";

import {ExchangeBaseRelayer} from "./abstract/ExchangeBaseRelayer.sol";

/**
 *  @notice ExchangeRelayer contract
 *  ERC-2771 compatible version of Exchange.
 *  User-facing write functions use _msgSender() instead of msg.sender
 *  to support meta-transactions via trusted forwarder.
 *
 *  NOTE: Original Exchange inherits Context for _msgSender(). In this version,
 *  we use RelayerModifier._msgSender() which handles ERC-2771 trusted forwarder logic.
 */

contract ExchangeRelayer is ExchangeBaseRelayer, IExchange {
    error RefundPermitTrue();

    // =======================================================================================================

    struct BoxExchengData {
        address _acceptedToken; // If address(0), then it means support officialToken
        address _seller; // If address(0), then it means by minter sell
        address _buyer;
        address _completer;
        uint256 _refundRequestDeadline;
        uint256 _refundReviewDeadline;
        bool _refundPermit;
    }

    mapping(uint256 boxId => BoxExchengData data) private _boxExchengData;

    // ========================================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) ExchangeBaseRelayer(addrManager_, trustedForwarder_) {}

    // ==========================================================================================================
    //                                          Override Functions
    // ==========================================================================================================

    function setAddress() external checkSetCaller {
        _setAddress();
    }

    // ========================================================================================================
    //                                           Checker functions
    // ========================================================================================================

    function _checkStatus(uint256 boxId_, Status status_) internal view {
        if (TRUTH_BOX.getStatus(boxId_) != status_) revert InvalidStatus();
    }

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

    /**
     * NOTE [ERC-2771]: msg.sender -> _msgSender() for user identity in listing
     */
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

        address sender = _msgSender(); // ERC-2771: extract real sender
        uint256 userId = USER_ID.getUserId(sender);
        address token = ADDR_MANAGER.officialToken();

        if (sender != truthBox.minterOf(boxId_)) {
            // others sell
            if (truthBox.getDeadline(boxId_) >= block.timestamp)
                revert DeadlineNotOver();
            _boxExchengData[boxId_]._seller = sender; // ERC-2771: use real sender

            // if the _seller is not the minter, they can't set the price
            price_ = 0;
        } else {
            // NOTE minter sell
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
    ) private {
        uint256 deadline = timestamp + _refundRequestPeriod;
        _boxExchengData[boxId_]._refundRequestDeadline = deadline;

        emit RequestDeadlineChanged(boxId_, deadline);
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

    /**
     * @notice Buy function
     * NOTE [ERC-2771]: _msgSender() used for buyer identity (already from RelayerModifier)
     */
    function buy(uint256 boxId_) external {
        ITruthBox truthBox = TRUTH_BOX;

        if (truthBox.getStatus(boxId_) != Status.Selling)
            revert InvalidStatus();

        truthBox.setStatus(boxId_, Status.Paid);

        address sender = _msgSender(); // ERC-2771: extract real sender
        uint256 userId = USER_ID.getUserId(sender);
        _boxExchengData[boxId_]._buyer = sender;

        _setRefundRequestDeadline(boxId_, block.timestamp);

        uint256 payAmount = truthBox.getPrice(boxId_);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount);

        emit BoxPurchased(boxId_, userId);
    }

    /**
     * @notice Bid function
     * NOTE [ERC-2771]: _msgSender() used for bidder identity
     */
    function bid(uint256 boxId_) external {
        address sender = _msgSender(); // ERC-2771: extract real sender
        if (sender == _buyerOf(boxId_)) revert InvalidCaller();

        uint256 price = _bid(boxId_);

        uint256 payAmount = _calcPayMoney(boxId_, sender, price);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount);

        _boxExchengData[boxId_]._buyer = sender;

        uint256 userId = USER_ID.getUserId(sender);
        emit BidPlaced(boxId_, userId);
    }

    function _bid(uint256 boxId_) internal returns (uint256) {
        ITruthBox truthBox = TRUTH_BOX;
        (Status status, uint256 price, uint256 deadline) = truthBox
            .getBasicData(boxId_);

        if (deadline < block.timestamp) revert DeadlineIsOver();
        if (status != Status.Auctioning) revert InvalidStatus();

        // NOTE: 30 days----3 days
        _setRefundRequestDeadline(boxId_, block.timestamp + 3 days);
        uint256 newPrice = (price * _bidIncrementRate) / 100;

        truthBox.setBasicData(
            boxId_,
            newPrice,
            Status.Auctioning,
            block.timestamp + 3 days
        );

        return price;
    }

    /**
     * @notice Calculate the pay amount (view function, SIWE-based)
     */
    function calcPayMoney(
        uint256 boxId_,
        bytes memory siweToken_
    ) public view returns (uint256) {
        address sender = _msgSenderSiwe(siweToken_);
        uint256 price = TRUTH_BOX.getPrice(boxId_);

        return _calcPayMoney(boxId_, sender, price);
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

    // ========================================================================================================
    //                                           Refund function
    // ========================================================================================================

    /**
     * @notice Request refund
     * NOTE [ERC-2771]: msg.sender -> _msgSender()
     */
    function requestRefund(uint256 boxId_) external {
        ITruthBox truthBox = TRUTH_BOX;
        if (truthBox.getStatus(boxId_) != Status.Paid) revert InvalidStatus();
        if (_msgSender() != _buyerOf(boxId_)) revert NotBuyer(); // ERC-2771
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
     * @notice Cancel refund
     * NOTE [ERC-2771]: msg.sender -> _msgSender()
     */
    function cancelRefund(uint256 boxId_) external {
        if (_msgSender() != _buyerOf(boxId_)) revert NotBuyer(); // ERC-2771
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        ITruthBox truthBox = TRUTH_BOX;
        if (truthBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();
        truthBox.setStatus(boxId_, Status.Delaying);
        FUND_MANAGER.allocationRewards(boxId_);
    }

    /**
     * @notice Agree refund
     * NOTE [ERC-2771]: msg.sender -> _msgSender() for role check
     */
    function agreeRefund(uint256 boxId_) external {
        ITruthBox truthBox = TRUTH_BOX;

        if (truthBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();

        if (isInReviewDeadline(boxId_)) {
            address sender = _msgSender(); // ERC-2771: extract real sender
            if (
                sender != truthBox.minterOf(boxId_) &&
                sender != ADDR_MANAGER.dao()
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
     * @notice Refuse refund
     * NOTE [ERC-2771]: msg.sender -> _msgSender() for DAO check
     */
    function refuseRefund(uint256 boxId_) external {
        ITruthBox truthBox = TRUTH_BOX;
        if (truthBox.getStatus(boxId_) != Status.Refunding)
            revert InvalidStatus();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();
        if (isInReviewDeadline(boxId_)) {
            if (_msgSender() != ADDR_MANAGER.dao()) revert InvalidCaller(); // ERC-2771
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
     * @notice Complete order
     * NOTE [ERC-2771]: msg.sender -> _msgSender() for buyer/minter/completer identity
     */
    function completeOrder(uint256 boxId_) external {
        ITruthBox truthBox = TRUTH_BOX;
        if (truthBox.getStatus(boxId_) != Status.Paid) revert InvalidStatus();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        address sender = _msgSender(); // ERC-2771: extract real sender
        if (sender != _buyerOf(boxId_)) {
            if (isInRequestRefundDeadline(boxId_)) revert DeadlineNotOver();
            if (sender != truthBox.minterOf(boxId_)) {
                _boxExchengData[boxId_]._completer = sender; // ERC-2771: use real sender
                uint256 userId = USER_ID.getUserId(sender);
                emit CompleterAssigned(boxId_, userId);
            }
        }
        truthBox.setStatus(boxId_, Status.Delaying);
        FUND_MANAGER.allocationRewards(boxId_);
    }

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

    function buyerOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (address) {
        return _buyerOf(boxId_);
    }

    function sellerOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (address) {
        return _boxExchengData[boxId_]._seller;
    }

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

    function acceptedToken(uint256 boxId_) external view returns (address) {
        address token = _boxExchengData[boxId_]._acceptedToken;
        if (token == address(0)) return ADDR_MANAGER.officialToken();
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

    // ========================================================================================================

    /**
     * @notice SIWE-based _msgSender for read (view) operations.
     * @dev Separate from ERC-2771 _msgSender() used for write operations.
     */
    function _msgSenderSiwe(
        bytes memory siweToken_
    ) internal view returns (address) {
        address sender = msg.sender;
        if (sender == address(0)) {
            sender = SIWE_AUTH.getMsgSender(siweToken_);
        }
        return sender;
    }

    // ----------------------------------------------------------------
    //                      Debugging Functions
    // ----------------------------------------------------------------

    function buyerOf_debug(uint256 boxId_) external view returns (address) {
        return _buyerOf(boxId_);
    }
    function sellerOf_debug(uint256 boxId_) external view returns (address) {
        return _boxExchengData[boxId_]._seller;
    }
    function completerOf_debug(uint256 boxId_) external view returns (address) {
        return _boxExchengData[boxId_]._completer;
    }

    // -------------------------------------------------------------------
}
