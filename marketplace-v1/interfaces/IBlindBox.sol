// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

enum Status {
    Storing,
    Selling,
    Auctioning,
    Paid,
    Refunding,
    Delaying,
    Published,
    Blacklisted
}

interface BlindBoxEvents {
    event BoxCreated(
        uint256 indexed boxId,
        bytes32 indexed userId,
        string boxInfoCID
    );
    event BoxStatusChanged(uint256 indexed boxId, Status status);
    event PriceChanged(uint256 indexed boxId, uint256 price);
    event DeadlineChanged(uint256 indexed boxId, uint256 deadline);
    event PrivateKeyPublished(
        uint256 boxId,
        bytes privateKey,
        bytes32 indexed userId
    );
}

/**
 * @title IBlindBox
 * @notice BlindBox contract interface, defining all externally exposed functions and events
 * @dev This interface serves as the top-level constraint for the BlindBox contract, ensuring consistency between interface and implementation
 */
interface IBlindBox {
    // =====================================================================================
    //                                          Address Management
    // =====================================================================================

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external;

    // =====================================================================================
    //                                          Box Creation
    // =====================================================================================

    /**
     * @notice Create a BlindBox
     * @param boxInfoCID_ CID of the box info
     * @param key_ Key of the box
     * @param price_ Price of the box
     * @return boxId The created Box ID
     */
    function create(
        string calldata boxInfoCID_,
        bytes calldata key_,
        uint256 price_
    ) external returns (uint256);

    /**
     * @notice Create and immediately publish a BlindBox
     * @param boxInfoCID_ CID of the box info
     * @return boxId The created Box ID
     */
    function createAndPublish(
        string calldata boxInfoCID_
    ) external returns (uint256);

    // =====================================================================================
    //                                          Getter Functions
    // =====================================================================================

    /**
     * @notice Get the status of a box
     * @param boxId_ Box ID
     * @return Status of the box
     */
    function getStatus(uint256 boxId_) external view returns (Status);

    /**
     * @notice Get the price of a box
     * @param boxId_ Box ID
     * @return Price of the box
     */
    function getPrice(uint256 boxId_) external view returns (uint256);

    /**
     * @notice Get the deadline of a box
     * @param boxId_ Box ID
     * @return Deadline of the box
     */
    function getDeadline(uint256 boxId_) external view returns (uint256);

    /**
     * @notice Get basic data of a box (status, price, deadline)
     * @param boxId_ Box ID
     * @return status Status of the box
     * @return price Price of the box
     * @return deadline Deadline of the box
     */
    function getBasicData(
        uint256 boxId_
    ) external view returns (Status, uint256, uint256);

    /**
     * @notice Get secret data of a box (key)
     * @param boxId_ Box ID
     * @param siweToken_ SIWE token of the user
     * @return key Key of the box
     */
    function getSecretData(
        uint256 boxId_,
        bytes memory siweToken_
    ) external view returns (bytes memory);

    // =====================================================================================
    //                                          Setter Functions (Project Contracts Only)
    // =====================================================================================

    /**
     * @notice Set the status of a box
     * @param boxId_ Box ID
     * @param status_ New status
     * @dev Only callable by project contracts
     */
    function setStatus(uint256 boxId_, Status status_) external;

    /**
     * @notice Set the price of a box
     * @param boxId_ Box ID
     * @param price_ New price
     * @dev Only callable by project contracts
     */
    function setPrice(uint256 boxId_, uint256 price_) external;

    /**
     * @notice Add deadline to a box
     * @param boxId_ Box ID
     * @param seconds_ Seconds to add
     * @dev Only callable by project contracts
     */
    function addDeadline(uint256 boxId_, uint256 seconds_) external;

    /**
     * @notice Set basic data of a box (price, status, deadline)
     * @param boxId_ Box ID
     * @param price_ New price
     * @param status_ New status
     * @param deadline_ New deadline
     * @dev Only callable by project contracts
     */
    function setBasicData(
        uint256 boxId_,
        uint256 price_,
        Status status_,
        uint256 deadline_
    ) external;

    // =====================================================================================
    //                                          Public Functions
    // =====================================================================================

    /**
     * @notice Publish BlindBox by minter
     * @param boxId_ Box ID
     * @dev Only callable by minter, box must be in Storing status
     */
    function publishByMinter(uint256 boxId_) external;

    /**
     * @notice Publish BlindBox by buyer
     * @param boxId_ Box ID
     * @dev Only callable by buyer, box must be in Delaying status
     */
    function publishByBuyer(uint256 boxId_) external;

    /**
     * @notice Extend the deadline
     * @param boxId_ Box ID
     * @param time_ Time to extend (in seconds)
     * @dev Only callable by minter, box must be in Storing status and within 30 days before deadline
     */
    function extendDeadline(uint256 boxId_, uint256 time_) external;

    /**
     * @notice Delay
     * @param boxId_ Box ID
     * @dev Box must be in Delaying status and within 30 days before deadline
     */
    function delay(uint256 boxId_) external;

    // =====================================================================================
    //                                          Blacklist Functions
    // =====================================================================================

    /**
     * @notice Add a box to the blacklist
     * @param boxId_ Box ID
     * @dev Only callable by DAO
     */
    function addToBlacklist(uint256 boxId_) external;

    /**
     * @notice Check if a box is in the blacklist
     * @param boxId_ Box ID
     * @return Whether the box is in the blacklist
     */
    function isInBlacklist(uint256 boxId_) external view returns (bool);

    // ================================================

    /**
     * @notice Get the minter userId of a box
     * @param boxId_ Box ID
     * @return minterId Minter userId of the box
     * @dev Only callable by project contracts
     */
    function minterIdOf(uint256 boxId_) external view returns (bytes32);
}
