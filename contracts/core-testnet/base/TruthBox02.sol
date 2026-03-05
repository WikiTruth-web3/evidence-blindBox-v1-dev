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

import {TruthBox01} from "./TruthBox01.sol";
import {TruthBoxEvents, Status} from "@marketplace-v1/interfaces/ITruthBox.sol";

/**
 *  @notice TruthBox contract
 *  Implement basic TruthBox functions, including mint, publish, blacklist, etc.
 *  Also includes important transaction-related functions, including setPrice, setDeadline, addDeadline, setStatus
 *  @dev Inherits ITruthBox interface to ensure consistency between interface and implementation
 */

contract TruthBox02 is TruthBox01, TruthBoxEvents, ERC2771Context, SiweContext {
    error InvalidToken();
    error EmptyKey();
    error DeadlineNotIn30days();
    error InvalidSeconds();

    struct BasicData {
        Status _status;
        uint256 _price;
        uint256 _deadline;
    }

    struct SecretData {
        address _minter;
        bytes _encryptedData; // sapphire encrypted data (private key)
        bytes32 _nonce; // sapphire encrypted nonce, decryption required
    }

    mapping(uint256 boxId => BasicData) internal _basicData;
    mapping(uint256 boxId => SecretData) internal _secretData;

    // ==================================================================================================
    constructor(
        address addrManager_,
        address trustedForwarder_
    ) TruthBox01(addrManager_) ERC2771Context(trustedForwarder_) {}

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

        if (key_.length != 0) {
            // Generate encrypted nonce (critical fix: save nonce for decryption)
            nonce = bytes32(
                Sapphire.randomBytes(32, abi.encodePacked(boxId, sender))
            );

            encryptedData = Sapphire.encrypt(
                bytes32(0), // Use default key, do not use automatically generated secretKey
                nonce,
                key_,
                ""
            );
        }

        _basicData[boxId] = BasicData({
            _price: price_,
            _status: status_,
            _deadline: deadline_
        });

        _secretData[boxId] = SecretData({
            _minter: sender,
            _nonce: nonce,
            _encryptedData: encryptedData
        });

        unchecked {
            _nextBoxId++;
        }

        uint256 userId = USER_MANAGER.getUserId(sender);
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

    //==================================================================================================
    //                                      Get Info Functions
    //==================================================================================================

    /**
     * @dev Get the status of a box
     * @param boxId_ The ID of the box
     * @return The status of the box
     */
    function _getStatus(uint256 boxId_) internal view returns (Status) {
        Status status = _basicData[boxId_]._status;
        // If the deadline has passed, then you need to judge the status of the box
        if (_basicData[boxId_]._deadline < block.timestamp) {
            // 1, Box in selling/auctioning, if there is no buyer, then the status is Published
            if (status == Status.Selling || status == Status.Auctioning) {
                if (EXCHANGE.buyerOf(boxId_) == address(0)) {
                    return Status.Published;
                } else {
                    // If there is a buyer, then the status is Paid
                    return Status.Paid;
                }
            } else if (status == Status.Delaying) {
                // 2, Box in Delaying status, then the status is Published
                return Status.Published;
            }
        }
        return status;
    }

    //==================================================================================================
    //                                      Get Info Functions
    //==================================================================================================

    function getStatus(uint256 boxId_) external view returns (Status) {
        return _getStatus(boxId_);
    }

    function getPrice(uint256 boxId_) external view returns (uint256) {
        return _basicData[boxId_]._price;
    }

    function getDeadline(uint256 boxId_) external view returns (uint256) {
        return _basicData[boxId_]._deadline;
    }

    // ==========================================================================================================

    /**
     * @dev Get public data of a box
     * @param boxId_ The ID of the box
     * @return status The status of the box
     * @return price The price of the box
     * @return deadline The deadline of the box
     */
    function getBasicData(
        uint256 boxId_
    ) external view returns (Status, uint256, uint256) {
        Status status = _getStatus(boxId_);
        return (
            status,
            _basicData[boxId_]._price,
            _basicData[boxId_]._deadline
        );
    }

    /**
     * @dev Get secret data of a box
     * @param boxId_ The ID of the box
     * @param siweToken_ The siwe token of the user
     * @return key The key of the box
     * siweToken_ The siwe token of the user
     */
    function getSecretData(
        uint256 boxId_,
        bytes memory siweToken_
    ) external view returns (bytes memory) {
        // Use SiweContext get sender
        address sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        if (sender == address(0)) revert InvalidToken();
        Status status = _getStatus(boxId_);

        if (
            status == Status.Storing ||
            status == Status.Selling ||
            status == Status.Auctioning
        ) {
            // The value of the status: if it is Storing, Selling, Auctioning, then check if the msg.sender is minter
            if (sender != _minterOf(boxId_)) revert InvalidCaller();
        } else if (status == Status.Delaying || status == Status.Paid) {
            // The value of the status: if it is Delaying, Paid, then check if the msg.sender is buyer
            if (sender != EXCHANGE.buyerOf(boxId_)) revert InvalidCaller();
        }
        // The value of the status:
        // if it is Published,Refunding, then everyone can view, no need to check

        return _decrypt(boxId_);
    }

    // ==========================================================================================================

    function _decrypt(uint256 boxId_) internal view returns (bytes memory) {
        return
            Sapphire.decrypt(
                bytes32(0), // Do not use secretKey, in order to keep its interface pure and stable.
                _secretData[boxId_]._nonce,
                _secretData[boxId_]._encryptedData,
                ""
            );
    }

    // ==================================================================================================

    function _checkStatus(uint256 boxId_, Status status_) internal view {
        if (_basicData[boxId_]._status != status_) revert InvalidStatus();
    }

    function _checkIsBlacklisted(uint256 boxId_) internal view {
        if (_basicData[boxId_]._status == Status.Blacklisted)
            revert InBlacklist();
    }

    // Check if the current time is within the 30 days of the deadline
    function _isDeadlineIn30days(uint256 boxId_) internal view {
        uint256 deadline = _basicData[boxId_]._deadline;
        if (
            deadline < block.timestamp || deadline > block.timestamp + 3 days // NOTE 30 days----3 days
        ) {
            revert DeadlineNotIn30days();
        }
    }

    //==================================================================================================
    //                                      Setter Functions
    //==================================================================================================
    function _setPrice(uint256 boxId_, uint256 price_) internal {
        // If the price_ is 0, then do not set
        if (price_ != 0) {
            _basicData[boxId_]._price = price_;
            emit PriceChanged(boxId_, price_);
        }
    }

    function _setDeadline(uint256 boxId_, uint256 deadline_) internal {
        if (deadline_ > block.timestamp) {
            _basicData[boxId_]._deadline = deadline_;
            emit DeadlineChanged(boxId_, deadline_);
        }
        // If the incoming deadline is less than the current time, then do not set
    }

    function _addDeadline(uint256 boxId_, uint256 seconds_) internal {
        if (seconds_ == 0) revert InvalidSeconds();
        uint256 newDeadline = _basicData[boxId_]._deadline + seconds_;
        _basicData[boxId_]._deadline = newDeadline;
        emit DeadlineChanged(boxId_, newDeadline);
    }

    function _setStatus(uint256 boxId_, Status status_) internal {
        // If the incoming status is Storing status, then do not set
        if (status_ == Status.Storing) revert InvalidStatus();
        // if (status_ == Status.Refunding) {
        //     address buyer = EXCHANGE.buyerOf(boxId_);
        //     uint256 userId = USER_MANAGER.getUserId(buyer);

        //     bytes memory privateKey = _decrypt(boxId_);
        //     emit PrivateKeyPublished(boxId_, privateKey, userId);
        // }
        if (status_ == Status.Delaying) {
            _setDeadline(boxId_, block.timestamp + 15 days); // NOTE 365----15
        }
        if (status_ != _basicData[boxId_]._status) {
            _basicData[boxId_]._status = status_;
            emit BoxStatusChanged(boxId_, status_);
        }
    }

    // ==========================================================================================================
    //                                                delay function
    // ==========================================================================================================

    // If the caster wishes to extend the confidentiality period, they will need to verify by minter account
    function extendDeadline(uint256 boxId_, uint256 time_) external {
        // erc2771 - _msgSender() is the real caller
        if (_msgSender() != _minterOf(boxId_)) revert InvalidCaller();
        _checkStatus(boxId_, Status.Storing);
        _isDeadlineIn30days(boxId_);
        if (time_ > 15 days) revert InvalidPeriod(); // NOTE: 365----15

        _addDeadline(boxId_, time_);
    }

    function _delay(uint256 boxId_) internal {
        uint256 amount = _basicData[boxId_]._price;

        FUND_MANAGER.payDelayFee(boxId_, _msgSender(), amount); // erc2771

        uint256 newPrice = (amount * _incrementRate) / 100;
        _setPrice(boxId_, newPrice);
        // NOTE: 365----15
        _addDeadline(boxId_, 15 days); // Here do not need to call safeAddDeadline, because the blacklist has been checked.
    }

    // ==========================================================================================================
    //                                               Blacklist Functions
    // ==========================================================================================================

    function addBoxToBlacklist(uint256 boxId_) external onlyDAO {
        _minterOf(boxId_);

        _checkIsBlacklisted(boxId_);

        // If the Box has a buyer, then set RefundPermit to true
        if (EXCHANGE.buyerOf(boxId_) != address(0)) {
            EXCHANGE.setRefundPermit(boxId_, true);
        }

        _basicData[boxId_]._status = Status.Blacklisted;

        emit BoxStatusChanged(boxId_, Status.Blacklisted);
    }

    function isInBlacklist(uint256 boxId_) public view returns (bool) {
        return _basicData[boxId_]._status == Status.Blacklisted;
    }

    // ==========================================================================================================
    //                                      Getter Functions
    // ==========================================================================================================
    function _minterOf(uint256 boxId_) internal view returns (address) {
        address minter = _secretData[boxId_]._minter;
        if (minter == address(0)) revert InvalidBoxId();
        return minter;
    }

    function minterOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (address) {
        return _minterOf(boxId_);
    }
}
