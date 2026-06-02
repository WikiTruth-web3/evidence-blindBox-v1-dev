// SPDX-License-Identifier: GPL-2.0-or-later
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.24;

import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import {IBlindBox} from "@interfaces/sapphire/IBlindBox.sol";
import {BoxStatus} from "@interfaces/base/BoxStatus.sol";

import {ExchangeEvents} from "@interfaces/IExchange.sol";
import {Exchange01} from "./Exchange01.sol";
// import {SiweContext} from "@siwe/SiweContext.sol";

/**
 *  @notice Exchange02 contract
 *  Implement basic BlindBox trading functions, including Selling, Auctioning, Paid, Refunding, Completed
 *  @dev Inherits IExchange interface to ensure consistency between interface and implementation
 */

contract Exchange02 is Exchange01, ExchangeEvents, ERC2771Context {
    // =======================================================================================================

    struct BoxExchengData {
        address _acceptedToken; // If address(0), then it means support settlementToken
        bytes32 _sellerId; // If address(0), then it means by minter sell
        bytes32 _buyerId;
        bytes32 _completerId;
        uint256 _refundRequestDeadline;
        uint256 _arbitrationDeadline;
        bool _refundPermit;
    }

    mapping(uint256 boxId => BoxExchengData data) internal _boxExchengData;

    // ========================================================================================================

    constructor(address addrManager_, address trustedForwarder_) Exchange01(addrManager_) ERC2771Context(trustedForwarder_) {}

    // ========================================================================================================
    //                                           Checker functions
    // ========================================================================================================

    /**
     * @notice Read box status
     * @param boxId_ Box ID
     * If the box status is Auctioning, and the deadline is over, then it is directly Paid.
     */
    // function _isStatus(uint256 boxId_, BoxStatus status_) internal view {
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

    function _isInArbitrationDeadline(uint256 boxId_) internal view returns (bool) {
        if (_boxExchengData[boxId_]._arbitrationDeadline < block.timestamp)
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
        BoxStatus status_,
        uint256 seconds_
    ) internal {
        IBlindBox BlindBox = BLIND_BOX;
        if (BlindBox.getStatus(boxId_) != BoxStatus.Storing)
            revert InvalidStatus();
        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();

        bytes32 userId = USER_MANAGER.getUserId(sender);
        address token = ADDR_MANAGER.settlementToken();

        if (userId != BlindBox.minterIdOf(boxId_)) {
            // others sell
            if (BlindBox.getDeadline(boxId_) >= block.timestamp) {
                revert DeadlineNotOver();
            }
            _boxExchengData[boxId_]._sellerId = userId;

            // if the _sellerId is not the minter, they can't set the price
            price_ = 0;
        } else {
            if (
                acceptedToken_ != token && 
                ADDR_MANAGER.isTokenSupported(acceptedToken_)
            ) {
                
                _boxExchengData[boxId_]._acceptedToken = acceptedToken_;
                token = acceptedToken_;
            }
        }

        BlindBox.setBasicData(
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

    function _setRefundPermitTrue(uint256 boxId_) internal {
        _boxExchengData[boxId_]._refundPermit = true;
        emit RefundPermitChanged(boxId_, true);
    }

    // ========================================================================================================
    //                                           Getter function
    // ========================================================================================================

    function _buyerIdOf(uint256 boxId_) internal view returns (bytes32) {
        return _boxExchengData[boxId_]._buyerId;
    }

    function _sellerIdOf(uint256 boxId_) internal view returns (bytes32) {
        return _boxExchengData[boxId_]._sellerId;
    }

    function _completerIdOf(uint256 boxId_) internal view returns (bytes32) {
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

    function _arbitrationDeadline(
        uint256 boxId_
    ) internal view returns (uint256) {
        return _boxExchengData[boxId_]._arbitrationDeadline;
    }

    function _refundRequestDeadline(
        uint256 boxId_
    ) internal view returns (uint256) {
        return _boxExchengData[boxId_]._refundRequestDeadline;
    }

    // -------------------------------------------------------------------
}