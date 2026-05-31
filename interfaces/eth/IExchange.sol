// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {Status} from "./IBlindBox.sol";

interface ExchangeEvents {
    event BoxListed(
        uint256 indexed boxId,
        bytes32 userId,
        address acceptedToken
    );
    event BoxPurchased(uint256 indexed boxId, bytes32 indexed userId);
    event BidPlaced(uint256 indexed boxId, bytes32 indexed userId);
    event CompleterAssigned(uint256 indexed boxId, bytes32 indexed userId);
    event RequestDeadlineChanged(uint256 indexed boxId, uint256 deadline);
    event ArbitrationDeadineChanged(uint256 indexed boxId, uint256 deadline);
    event RefundPermitChanged(uint256 indexed boxId, bool permission);
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
    function setContracts() external;

    // =====================================================================================
    //                                          Refund Functions
    // =====================================================================================
    /**
     * @notice Set refund permit status
     * @param boxId_ Box ID
     * @dev Only callable by project contracts
     */
    function setRefundPermitTrue(uint256 boxId_) external;

    // =====================================================================================
    //                                          Buying Functions
    // =====================================================================================

    /**
     * @notice Buy a box
     * @param boxId_ Box ID
     * @dev Only callable by project contracts
     */
    function buy(uint256 boxId_) external;

    /**
     * @notice Place a bid on an auction
     * @param boxId_ Box ID
     * @dev Only callable by project contracts
     */
    function bid(uint256 boxId_) external;

    /**
     * @notice Place a bid on an auction
     * @param boxId_ Box ID
     * @param userId_ User ID is bytes32
     * @dev Only callable by project contracts
     */
    function calcPayAmount(uint256 boxId_, bytes32 userId_) external view returns (uint256);

    /**
     * @notice Complete an order
     * @param boxId_ Box ID
     * @dev Buyer can call anytime, others can call after refund deadline
     */
    function completeOrder(uint256 boxId_) external;

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
     * @notice Get seller address
     * @param boxId_ Box ID
     * @return Seller address (address(0) means minter is the seller)
     * @dev Only callable by project contracts
     */
    function sellerIdOf(uint256 boxId_) external view returns (bytes32);

    /**
     * @notice Get completer address
     * @param boxId_ Box ID
     * @return Completer address
     * @dev Only callable by project contracts
     */
    function completerIdOf(uint256 boxId_) external view returns (bytes32);


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
     * @notice Get refund arbitration deadline
     * @param boxId_ Box ID
     * @return Refund arbitration deadline timestamp
     */
    function arbitrationDeadline(
        uint256 boxId_
    ) external view returns (uint256);

    /**
     * @notice Check if box is within refund request deadline
     * @param boxId_ Box ID
     * @return Whether box is within refund request deadline
     */
    // function isInRequestRefundDeadline(
    //     uint256 boxId_
    // ) external view returns (bool);

    /**
     * @notice Check if box is within refund arbitration deadline
     * @param boxId_ Box ID
     * @return Whether box is within refund arbitration deadline
     */
    // function isInArbitrationDeadline(uint256 boxId_) external view returns (bool);

    // =====================================================================================
}