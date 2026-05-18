// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {BlindBox01} from "./BlindBox01.sol";
import {BlindBoxEvents, Status} from "@interfaces/eth/IBlindBox.sol";

/**
 *  @notice BlindBox contract
 *  Implement basic BlindBox functions, including mint, publish, blacklist, etc.
 *  Also includes important transaction-related functions, including setPrice, setDeadline, addDeadline, setStatus
 *  @dev Inherits IBlindBox interface to ensure consistency between interface and implementation
 */

contract BlindBox02 is BlindBox01, BlindBoxEvents {
    struct BasicData {
        Status _status;
        uint256 _price;
        uint256 _deadline;
    }

    struct SecretData {
        bytes32 _minterId;
        bytes _encryptedData; // sapphire encrypted data (private key)
        bytes32 _nonce; // sapphire encrypted nonce, decryption required
    }

    mapping(uint256 boxId => BasicData) internal _basicData;
    mapping(uint256 boxId => SecretData) internal _secretData;

    // ==================================================================================================
    constructor(address addrManager_) BlindBox01(addrManager_) {}

    // ==========================================================================================================
    //                                                 mint Functions
    // ==========================================================================================================

    /**
     * @dev Set the box data
     * @param boxInfoCID_ The CID of the box info
     * @param price_ The price of the box
     * @param status_ The status of the box
     * @param deadline_ The deadline of the box
     * @param key_ The key of the box
     * @return The ID of the box
     */
    function _setBoxData(
        string calldata boxInfoCID_,
        uint256 price_,
        Status status_,
        uint256 deadline_,
        bytes memory key_
    ) internal returns (uint256) {
        uint256 boxId = _nextBoxId;

        // erc2771 - msg.sender is the real caller
        address sender = msg.sender;
        bytes32 userId = USER_MANAGER.getUserId(sender);

        _basicData[boxId] = BasicData({
            _price: price_,
            _status: status_,
            _deadline: deadline_
        });

        _secretData[boxId] = SecretData({
            _minterId: userId,
            _nonce: bytes32(0),
            _encryptedData: key_
        });

        unchecked {
            _nextBoxId++;
        }

        emit BoxCreated(boxId, userId, boxInfoCID_);

        return boxId;
    }

    function _checkCID(string calldata boxInfoCID_) internal pure {
        if (bytes(boxInfoCID_).length == 0) revert EmptyBoxInfoCID();
    }

    /**
     * @dev Create a truth box
     * @param boxInfoCID_ The CID of the box info
     * @param key_ The key of the box
     * @param price_ The price of the box
     * @return The ID of the box
     */
    function _create(
        string calldata boxInfoCID_,
        bytes calldata key_,
        uint256 price_
    ) internal returns (uint256) {
        if (key_.length == 0) revert EmptyKey();
        if (price_ == 0) revert EmptyPrice();
        _checkCID(boxInfoCID_);

        uint256 deadline;

        unchecked {
            // On mainnet, the deadline is 365 days, but on testnet, the deadline is 15 days
            deadline = block.timestamp + 365 days; // NOTE 365 days----15 days
        }

        uint256 boxId = _setBoxData(
            boxInfoCID_,
            price_,
            Status.Storing,
            deadline,
            key_
        );

        emit PriceChanged(boxId, price_);
        emit DeadlineChanged(boxId, deadline);
        // Log the price and deadline, do not record status, because status is Storing status

        return boxId;
    }

    function _createAndPublish(
        string calldata boxInfoCID_
    ) internal returns (uint256) {
        _checkCID(boxInfoCID_);

        uint256 boxId = _setBoxData(boxInfoCID_, 0, Status.Published, 0, "");

        emit BoxStatusChanged(boxId, Status.Published);
        return boxId;
    }

    // ==========================================================================================================
    function _checkMinter(uint256 boxId_) internal view {
        bytes32 userId = USER_MANAGER.getUserId(msg.sender);
        if (userId != _secretData[boxId_]._minterId) revert NotMinter();
    }

    function _checkBuyer(uint256 boxId_) internal view {
        bytes32 userId = USER_MANAGER.getUserId(msg.sender);
        if (userId != EXCHANGE.buyerIdOf(boxId_)) revert NotBuyer();
    }

    function _boxExists(uint256 boxId_) internal view {
        if (boxId_ >= _nextBoxId) revert BoxNotExists();
    }
}
