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


import "@openzeppelin/contracts/utils/Context.sol";

import {ITruthBox, Status} from "@wikitruth-v1/interfaces/ITruthBox.sol";
import {IExchange} from "@wikitruth-v1/interfaces/IExchange.sol";

import {ExchangeBase} from "./abstract/ExchangeBase.sol";

/**
 *  @notice Exchange contract
 *  Implement basic TruthBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange is Context, ExchangeBase, IExchange {
    // error Paused();
    // error InvalidPrice();

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

    constructor (address addrManager_) ExchangeBase(addrManager_) {
        
    }

    // ==========================================================================================================
    //                                          Override Functions
    // ==========================================================================================================
    
    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external checkSetCaller {
        _setAddress();
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
    function isInRequestRefundDeadline(uint256 boxId_) public view returns (bool) {
        _checkStatus(boxId_, Status.Paid);

        if (_boxExchengData[boxId_]._refundRequestDeadline < block.timestamp) return false;
        return true;
    }

    function isInReviewDeadline(uint256 boxId_) public view returns (bool) {
        _checkStatus(boxId_, Status.Refunding);
        if (_boxExchengData[boxId_]._refundReviewDeadline < block.timestamp) return false;
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
        if (truthBox.getStatus(boxId_) != Status.Storing) revert InvalidStatus();
        uint256 userId = USER_ID.getUserId(msg.sender);
        address token = ADDR_MANAGER.officialToken();

        if (msg.sender != truthBox.minterOf(boxId_)) {
            // others sell
            if (truthBox.getDeadline(boxId_) >= block.timestamp) revert DeadlineNotOver();
            _boxExchengData[boxId_]._seller = msg.sender;
            
            // if the _seller is not the minter, they can't set the price
            price_ = 0;
        } else {
            // NOTE minter sell
            // if the acceptedToken_ is not official, set it as acceptedToken
            if (acceptedToken_ != token) {
                if (!ADDR_MANAGER.isTokenSupported(acceptedToken_)) return;
                
                _boxExchengData[boxId_]._acceptedToken = acceptedToken_;
                token = acceptedToken_;
            }
        }
        truthBox.setBasicData(boxId_, price_, status_, block.timestamp + seconds_);

        emit BoxListed(boxId_, userId, token);
    }

    function _setRefundRequestDeadline(uint256 boxId_, uint256 timestamp) private {
        uint256 deadline = timestamp+ _refundRequestPeriod;
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
        _setBoxListedArgs(boxId_, acceptedToken_, price_, Status.Selling, 15 days);
    }

    function auction(
        uint256 boxId_, 
        address acceptedToken_,
        uint256 price_
    ) external {
        // NOTE: 30 days----3 days
        _setBoxListedArgs(boxId_, acceptedToken_, price_, Status.Auctioning, 3 days);
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
        if (truthBox.getStatus(boxId_) != Status.Selling) revert InvalidStatus();

        truthBox.setStatus(boxId_, Status.Paid);

        address sender = _msgSender();
        uint256 userId = USER_ID.getUserId(sender);
        _boxExchengData[boxId_]._buyer = sender;

        // Buy operation, should directly set the deadline for applying for refund
        _setRefundRequestDeadline(boxId_, block.timestamp);

        uint256 payAmount = truthBox.getPrice(boxId_);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount); // 转账

        emit BoxPurchased( boxId_, userId);
    }

    /**
     * @notice Bid function, the bidder needs to pay a higher price to get the bid资格
     * @param boxId_ Box ID
     * Need to check: deadline、status、buyer.
     * Bid will modify: buyer、price、deadline.
     * Bid also needs to calculate, and pay: payAmount
     */
    function bid(uint256 boxId_) external {
        
        address sender = _msgSender();
        if (sender == _buyerOf(boxId_)) revert InvalidCaller();
        
        uint256 price = _bid(boxId_);

        uint256 payAmount = _calcPayMoney( boxId_, sender, price);
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount); // need approve to FUND_MANAGER。
        
        _boxExchengData[boxId_]._buyer = sender;

        uint256 userId = USER_ID.getUserId(sender);
        emit BidPlaced(boxId_, userId);
    }

    /**
     * @notice Bid function, the bidder needs to pay a higher price to get the bid资格
     * @param boxId_ Box ID
     */
    function _bid(uint256 boxId_) internal returns(uint256) {
        ITruthBox truthBox = TRUTH_BOX;
        (Status status, uint256 price, uint256 deadline) = truthBox.getBasicData(boxId_);
        
        // canBid?
        if (deadline < block.timestamp) revert DeadlineIsOver();
        if (status != Status.Auctioning) revert InvalidStatus();

        // NOTE: 30 days----3 days
        _setRefundRequestDeadline(boxId_, block.timestamp + 3 days);
        uint256 newPrice = price * _bidIncrementRate / 100; // If bidIncrementRate is 110, then it is 110%

        truthBox.setBasicData(boxId_, newPrice, Status.Auctioning, block.timestamp + 3 days);
        
        return price;
    }

    /**
     * @notice Calculate the pay amount
     * @param boxId_ Box ID
     * @param siweToken_ The siwe token of the user
     * @return The pay amount
     */
    function calcPayMoney(uint256 boxId_, bytes memory siweToken_) public view returns (uint256) {
        address sender = _msgSender(siweToken_);
        uint256 price = TRUTH_BOX.getPrice(boxId_);

        return _calcPayMoney( boxId_, sender, price);
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
        if (msg.sender != _buyerOf(boxId_)) revert NotBuyer();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        if (isInRequestRefundDeadline(boxId_)) {

            uint256 deadline = block.timestamp + _refundReviewPeriod;
            _boxExchengData[boxId_]._refundReviewDeadline = deadline;
            truthBox.setStatus(boxId_, Status.Refunding);

            emit ReviewDeadlineChanged(boxId_, deadline);

        } else {
            truthBox.setStatus(boxId_, Status.InSecrecy);
            FUND_MANAGER.allocationRewards(boxId_);
        }
    }

    /**
     * @notice Cancel refund function, after canceling refund, the box status becomes Sold
     */
    function cancelRefund(uint256 boxId_) external  {
        if (msg.sender != _buyerOf(boxId_)) revert NotBuyer();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();

        // _checkStatus(boxId_, Status.Refunding);
        ITruthBox truthBox = TRUTH_BOX;
        if (truthBox.getStatus(boxId_) != Status.Refunding) revert InvalidStatus();
        truthBox.setStatus(boxId_, Status.InSecrecy);
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
        if (truthBox.getStatus(boxId_) != Status.Refunding) revert InvalidStatus();
        
        if (isInReviewDeadline(boxId_)) {
            // Check role: minter、DAO
            if (
                msg.sender != truthBox.minterOf(boxId_) && 
                msg.sender != ADDR_MANAGER.dao()
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
    function refuseRefund(uint256 boxId_) external  {
        // _checkStatus(boxId_, Status.Refunding);
        ITruthBox truthBox = TRUTH_BOX;
        // canRefuse?
        if (truthBox.getStatus(boxId_) != Status.Refunding) revert InvalidStatus();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();
        // According to whether it is within the review deadline, determine.
        if (isInReviewDeadline(boxId_)) {
            // Check role: DAO
            if (msg.sender != ADDR_MANAGER.dao()) revert InvalidCaller();
            truthBox.setStatus(boxId_, Status.InSecrecy);
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
     * Complete order also needs to set the status of TRUTH_BOX to InSecrecy
     * Complete order also needs to set refundRequestDeadline.
     */
    function completeOrder(uint256 boxId_) external {
        // _checkStatus(boxId_, Status.Paid);
        ITruthBox truthBox = TRUTH_BOX;
        // canComplete?
        if (truthBox.getStatus(boxId_) != Status.Paid) revert InvalidStatus();
        if (_refundPermit(boxId_)) revert RefundPermitTrue();
        
        if (msg.sender != _buyerOf(boxId_)) {
            if (isInRequestRefundDeadline(boxId_)) revert DeadlineNotOver();
            if (msg.sender != truthBox.minterOf(boxId_)) {
                _boxExchengData[boxId_]._completer = msg.sender;
                uint256 userId = USER_ID.getUserId(msg.sender);
                emit CompleterAssigned(boxId_,userId);
            }
        }
        truthBox.setStatus(boxId_, Status.InSecrecy);
        FUND_MANAGER.allocationRewards(boxId_);

    }

    // ========================================================================================================
    
    function setRefundPermit(uint256 boxId_, bool permission_) external onlyProjectContract{
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
    function buyerOf(uint256 boxId_) external view onlyProjectContract returns (address) {
        return _buyerOf(boxId_);
    }

    /* NOTE If the _seller is address(0), 
    * it means that the _seller is the minter
    */
    function sellerOf(uint256 boxId_) external view onlyProjectContract returns (address) {
        return _boxExchengData[boxId_]._seller;
    }

    /**
     * @notice Get completer address
     * @param boxId_ Box ID
     * @return Completer address
     */
    function completerOf(uint256 boxId_) external view onlyProjectContract returns (address) {
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
        if (token == address(0)) return ADDR_MANAGER.officialToken();
        return token;
    }

    function refundReviewDeadline(uint256 boxId_) external view returns (uint256) {
        return _boxExchengData[boxId_]._refundReviewDeadline;
    }

    function refundRequestDeadline(uint256 boxId_) external view returns (uint256) {
        return _boxExchengData[boxId_]._refundRequestDeadline;
    }

    // ========================================================================================================

    /**
     * @notice verify the sender is correct
     * @param siweToken_ The siwe token of the user 
     * @return The sender of the function
     * In sapphire, msg.sender is the zero address, so we need to get sender through siweToken_
     */
    function _msgSender(bytes memory siweToken_) internal view returns (address) {
        address sender = msg.sender;
        if (sender == address(0)) {
            sender = SIWE_AUTH.getMsgSender(siweToken_);
        }
        return sender;
    }

    // ----------------------------------------------------------------
    //                      Debugging Functions
    // ----------------------------------------------------------------

    // NOTE Debugging function. Production environment does not need this.
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
