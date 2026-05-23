// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {Status} from "./IBlindBox.sol";

interface ExchangeEvents {
    event BoxListed(
        uint256 indexed boxId,
        address acceptedToken
    );
    event BoxPurchased(uint256 indexed boxId, bytes32 indexed userId);
    event BidPlaced(uint256 indexed boxId, bytes32 indexed userId);
    event RequestDeadlineChanged(uint256 indexed boxId, uint256 deadline);
    event ReviewDeadlineChanged(uint256 indexed boxId, uint256 deadline);
    event RefundPermitChanged(uint256 indexed boxId, bool permission);
    // event CrossChainOrderCompleted(uint256 indexed boxId, bytes32 indexed buyerUserId);
    // event CrossChainRefundPermitted(uint256 indexed boxId, bytes32 indexed buyerUserId);
}

enum PaymentType {
    Native,
    CrossChain
}

/**
 * @title IExchange
 * @notice Exchange contract interface, defining all externally exposed functions and events
 * @dev This interface serves as the top-level constraint for the Exchange contract, ensuring consistency between interface and implementation
 */
interface IExchange {
    // =====================================================================================
    //                                          Address Management
    // =====================================================================================

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setCoreContracts() external;

    // =====================================================================================
    //                                          Refund Functions
    // =====================================================================================
    /**
     * @notice Set refund permit status
     * @param boxId_ Box ID
     * @param status_ Refund permit status
     * @dev Only callable by project contracts
     */
    function setRefundPermitTrue(uint256 boxId_, Status status_) external;

    // =====================================================================================
    //                                          Buying Functions
    // =====================================================================================

    /**
     * @notice Buy a box
     * @param boxId_ Box ID
     * @param buyerUserId_ User ID
     * @param payType_ Payment type
     * @dev Only callable by project contracts
     */
    function buy(
        uint256 boxId_,
        bytes32 buyerUserId_,
        PaymentType payType_
    ) external;

    /**
     * @notice Place a bid on an auction
     * @param boxId_ Box ID
     * @param buyerUserId_ User ID
     * @param price_ The bid price
     * @param payType_ Payment type
     * @dev Only callable by project contracts
     */
    function bid(
        uint256 boxId_,
        bytes32 buyerUserId_,
        uint256 price_,
        PaymentType payType_
    ) external;

    // =====================================================================================
    //                                          Getter Functions
    // =====================================================================================

    /**
     * @notice Get buyer address
     * @param boxId_ Box ID
     * @return Buyer address
     * @dev Only callable by project contracts
     */
    function buyerIdOf(uint256 boxId_) external view returns (bytes32);

    /**
     * @notice Get accepted token address
     * @param boxId_ Box ID
     * @return Accepted token address
     */
    function acceptedToken(uint256 boxId_) external view returns (address);

    /**
     * @notice Get refund permit status
     * @param boxId_ Box ID
     * @return Whether refund is permitted
     */
    function refundPermit(uint256 boxId_) external view returns (bool);

    /**
     * @notice Get refund request deadline
     * @param boxId_ Box ID
     * @return Refund request deadline timestamp
     */
    function refundRequestDeadline(
        uint256 boxId_
    ) external view returns (uint256);

    /**
     * @notice Get refund review deadline
     * @param boxId_ Box ID
     * @return Refund review deadline timestamp
     */
    function refundReviewDeadline(
        uint256 boxId_
    ) external view returns (uint256);

    /**
     * @notice Check if box is within refund request deadline
     * @param boxId_ Box ID
     * @return Whether box is within refund request deadline
     */
    function isInRequestRefundDeadline(
        uint256 boxId_
    ) external view returns (bool);

    /**
     * @notice Check if box is within refund review deadline
     * @param boxId_ Box ID
     * @return Whether box is within refund review deadline
     */
    function isInReviewDeadline(uint256 boxId_) external view returns (bool);

    /**
     * @notice Get payment type
     * @param boxId_ Box ID
     * @return Payment type (Native/CrossChain)
     */
    function paymentTypeOf(uint256 boxId_) external view returns (PaymentType);

    // =====================================================================================
}
