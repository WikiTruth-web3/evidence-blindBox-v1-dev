// SPDX-License-Identifier: GPL-2.0-or-later
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.24;

// import {
//     ERC2771Context
// } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import {IBlindBox, Status} from "@interfaces/eth/IBlindBox.sol";
import {ExchangeEvents, PaymentType} from "@interfaces/eth/IExchange.sol";
import {Exchange01} from "./Exchange01.sol";
// import {SiweContext} from "@siwe/SiweContext.sol";

/**
 *  @notice Exchange02 contract
 *  Implement basic BlindBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange02 is Exchange01, ExchangeEvents {
    // =======================================================================================================

    struct BoxExchengData {
        string chainToken; // Chain-specific token name
        address _acceptedToken; // If address(0), then it means support settlementToken
        bytes32 _buyerId;
        uint256 _refundRequestDeadline;
        uint256 _refundReviewDeadline;
        bool _refundPermit;
        PaymentType _paymentType;
    }

    mapping(uint256 boxId => BoxExchengData data) internal _boxExchengData;

    // ========================================================================================================

    constructor(address addrManager_) Exchange01(addrManager_) {}

    // ========================================================================================================
    //                                           Checker functions
    // ========================================================================================================

    /**
     * @notice Read box status
     * @param boxId_ Box ID
     * If the box status is Auctioning, and the deadline is over, then it is directly Paid.
     */
    // function _isStatus(uint256 boxId_, Status status_) internal view {
    //     if (BLIND_BOX.getStatus(boxId_) != status_) revert InvalidStatus();
    // }

    // Check the refund timestamp. Within the refund time,
    // you can apply for a refund (set to refunding mode),
    function _isInRequestRefundDeadline(
        uint256 boxId_
    ) internal view returns (bool) {
        if (_boxExchengData[boxId_]._refundRequestDeadline < block.timestamp)
            return false;
        return true;
    }

    function _isInReviewDeadline(uint256 boxId_) internal view returns (bool) {
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
        IBlindBox BlindBox = BLIND_BOX;
        if (BlindBox.getStatus(boxId_) != Status.Storing)
            revert InvalidStatus();
        // erc2771 - _msgSender() is the real caller
        // address sender = _msgSender();
        address sender = msg.sender;

        bytes32 userId = USER_MANAGER.getUserId(sender);
        address token = ADDR_MANAGER.settlementToken();

        if (userId != BlindBox.minterIdOf(boxId_)) revert NotMinter();

        if (acceptedToken_ != token ) {
            ADDR_MANAGER.checkTokenSupported(acceptedToken_);
            _boxExchengData[boxId_]._acceptedToken = acceptedToken_;
            token = acceptedToken_;
        }

        BlindBox.setBasicData(
            boxId_,
            price_,
            status_,
            block.timestamp + seconds_
        );

        emit BoxListed(boxId_, token);
    }

    function _setRefundRequestDeadline(
        uint256 boxId_,
        uint256 timestamp
    ) internal {
        uint256 deadline = timestamp + _refundRequestPeriod;
        _boxExchengData[boxId_]._refundRequestDeadline = deadline;

        emit RequestDeadlineChanged(boxId_, deadline);
    }

    function _setRefundPermit(uint256 boxId_, bool permission_) internal {
        _boxExchengData[boxId_]._refundPermit = permission_;
        emit RefundPermitChanged(boxId_, permission_);
    }

    // =========================================================================================================
    //                                           Funds Functions
    // ========================================================================================================
        function _processAllocation(uint256 boxId_) internal {
        if (_boxExchengData[boxId_]._paymentType == PaymentType.Native) {
            FUND_MANAGER.allocationRewards(boxId_);
        } else {
            FUND_MANAGER_CROSS_CHAIN.allocationRewards(boxId_);
            
        }
    }


    // ========================================================================================================
    //                                           Getter function
    // ========================================================================================================

    function _buyerIdOf(uint256 boxId_) internal view returns (bytes32) {
        return _boxExchengData[boxId_]._buyerId;
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
