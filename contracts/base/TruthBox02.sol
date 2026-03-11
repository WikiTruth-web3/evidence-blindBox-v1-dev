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

import {
    Sapphire
} from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import {SiweContext} from "@siwe/SiweContext.sol";
import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {IdentitySalt} from "../abstract/IdentitySalt.sol";
import {SecretKeyManager} from "../abstract/SecretKeyManager.sol";
import {TruthBox01} from "./TruthBox01.sol";
import {TruthBoxEvents, Status} from "@marketplace-v1/interfaces/ITruthBox.sol";

/**
 *  @notice TruthBox contract
 *  Implement basic TruthBox functions, including mint, publish, blacklist, etc.
 *  Also includes important transaction-related functions, including setPrice, setDeadline, addDeadline, setStatus
 *  @dev Inherits ITruthBox interface to ensure consistency between interface and implementation
 */

contract TruthBox02 is
    TruthBox01,
    TruthBoxEvents,
    ERC2771Context,
    SiweContext,
    SecretKeyManager
{
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
    constructor(
        address addrManager_,
        address trustedForwarder_
    )
        TruthBox01(addrManager_)
        ERC2771Context(trustedForwarder_)
        SecretKeyManager("WikiTruth Data Encryption Root Secret")
    {}

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

        bytes32 nonce;
        bytes memory encryptedData;

        // erc2771 - _msgSender() is the real caller
        address sender = _msgSender();
        bytes32 userId = USER_MANAGER.getUserId(sender);

        if (key_.length != 0) {
            // 1. Derive box-specific symmetric key
            bytes32 secretKey = _deriveDataKey(bytes32(boxId));

            // 2. Generate random nonce
            nonce = bytes32(
                Sapphire.randomBytes(32, abi.encodePacked(boxId, sender))
            );

            // 3. Encrypt data with the derived key
            encryptedData = Sapphire.encrypt(secretKey, nonce, key_, "");
        }

        _basicData[boxId] = BasicData({
            _price: price_,
            _status: status_,
            _deadline: deadline_
        });

        _secretData[boxId] = SecretData({
            _minterId: userId,
            _nonce: nonce,
            _encryptedData: encryptedData
        });

        unchecked {
            _nextBoxId++;
        }

        emit BoxCreated(boxId, userId, boxInfoCID_);

        return boxId;
    }

    function _checkCID(
        string calldata tokenCID_,
        string calldata boxInfoCID_
    ) internal pure {
        if (bytes(tokenCID_).length == 0) revert EmptyTokenCID();
        if (bytes(boxInfoCID_).length == 0) revert EmptyBoxInfoCID();
    }

    /**
     * @dev Create a truth box
     * @param tokenCID_ The CID of the token
     * @param boxInfoCID_ The CID of the box info
     * @param key_ The key of the box
     * @param price_ The price of the box
     * @return The ID of the box
     */
    function _create(
        string calldata tokenCID_,
        string calldata boxInfoCID_,
        bytes calldata key_,
        uint256 price_
    ) internal returns (uint256) {
        if (key_.length == 0) revert EmptyKey();
        if (price_ == 0) revert EmptyPrice();
        _checkCID(tokenCID_, boxInfoCID_);

        uint256 deadline;

        unchecked {
            // On mainnet, the deadline is 365 days, but on testnet, the deadline is 15 days
            deadline = block.timestamp + 15 days; // NOTE mainnet 365 days----testnet 15 days
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
        string calldata tokenCID_,
        string calldata boxInfoCID_
    ) internal returns (uint256) {
        _checkCID(tokenCID_, boxInfoCID_);

        uint256 boxId = _setBoxData(boxInfoCID_, 0, Status.Published, 0, "");

        emit BoxStatusChanged(boxId, Status.Published);
        return boxId;
    }
}
