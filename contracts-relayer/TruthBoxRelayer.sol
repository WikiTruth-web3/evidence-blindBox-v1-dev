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

import {TruthBoxBaseRelayer} from "./abstract/TruthBoxBaseRelayer.sol";
import {ITruthBox, Status} from "@wikitruth-v1/interfaces/ITruthBox.sol";

/**
 *  @notice TruthBoxRelayer contract
 *  ERC-2771 compatible version of TruthBox.
 *  User-facing write functions use _msgSender() instead of msg.sender
 *  to support meta-transactions via trusted forwarder.
 */

contract TruthBoxRelayer is TruthBoxBaseRelayer, ITruthBox {
    error InvalidToken();
    error EmptyKey();
    error DeadlineNotIn30days();
    error InvalidSeconds();

    struct PublicData {
        Status _status;
        uint256 _price;
        uint256 _deadline;
    }

    struct SecretData {
        address _minter;
        bytes _encryptedData; // Encrypted data (private key)
        bytes32 _nonce; // Encrypted nonce, decryption required
    }

    mapping(uint256 boxId => PublicData) internal _publicData;
    mapping(uint256 boxId => SecretData) internal _secretData;

    // ==================================================================================================
    constructor(
        address addrManager_,
        address trustedForwarder_
    ) TruthBoxBaseRelayer(addrManager_, trustedForwarder_) {}

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
     *
     * NOTE [ERC-2771]: msg.sender -> _msgSender() for minter identity and randomness seed
     */
    function _setBoxData(
        string calldata boxInfoCID_,
        uint256 price_,
        Status status_,
        uint256 deadline_,
        bytes memory key_
    ) internal returns (uint256) {
        uint256 boxId = _nextBoxId;
        address sender = _msgSender(); // ERC-2771: extract real sender

        bytes32 nonce;
        bytes memory encryptedData;

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

        _publicData[boxId] = PublicData({
            _price: price_,
            _status: status_,
            _deadline: deadline_
        });

        _secretData[boxId] = SecretData({
            _minter: sender, // ERC-2771: use real sender as minter
            _nonce: nonce,
            _encryptedData: encryptedData
        });

        unchecked {
            _nextBoxId++;
        }

        uint256 userId = USER_ID.getUserId(sender); // ERC-2771: use real sender
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
     *
     * NOTE [ERC-2771]: msg.sender replaced with _msgSender() in _setBoxData
     */
    function create(
        address to_,
        string calldata tokenCID_,
        string calldata boxInfoCID_,
        bytes calldata key_,
        uint256 price_
    ) external returns (uint256) {
        if (key_.length == 0) revert EmptyKey();
        if (price_ == 0) revert EmptyPrice();
        _checkCID(tokenCID_, boxInfoCID_);

        uint256 deadline;

        unchecked {
            // On mainnet, the deadline is 365 days, but on testnet, the deadline is 15 days
            deadline = block.timestamp + 15 days; // NOTE 365----15
        }

        uint256 boxId = _setBoxData(
            boxInfoCID_,
            price_,
            Status.Storing,
            deadline,
            key_
        );

        NFT.mint(boxId, to_, tokenCID_);

        emit PriceChanged(boxId, price_);
        emit DeadlineChanged(boxId, deadline);

        return boxId;
    }

    /**
     * NOTE [ERC-2771]: msg.sender replaced with _msgSender() in _setBoxData
     */
    function createAndPublish(
        address to_,
        string calldata tokenCID_,
        string calldata boxInfoCID_
    ) external returns (uint256) {
        _checkCID(tokenCID_, boxInfoCID_);

        uint256 boxId = _setBoxData(boxInfoCID_, 0, Status.Published, 0, "");

        NFT.mint(boxId, to_, tokenCID_);

        emit BoxStatusChanged(boxId, Status.Published);
        return boxId;
    }

    //==================================================================================================
    //                                      Get Info Functions
    //==================================================================================================

    function _getStatus(uint256 boxId_) internal view returns (Status) {
        Status status = _publicData[boxId_]._status;
        if (_publicData[boxId_]._deadline < block.timestamp) {
            if (status == Status.Selling || status == Status.Auctioning) {
                if (EXCHANGE.buyerOf(boxId_) == address(0)) {
                    return Status.Published;
                } else {
                    return Status.Paid;
                }
            } else if (status == Status.Delaying) {
                return Status.Published;
            }
        }
        return status;
    }

    function getStatus(uint256 boxId_) external view returns (Status) {
        return _getStatus(boxId_);
    }

    function getPrice(uint256 boxId_) external view returns (uint256) {
        return _publicData[boxId_]._price;
    }

    function getDeadline(uint256 boxId_) external view returns (uint256) {
        return _publicData[boxId_]._deadline;
    }

    // ==========================================================================================================

    function getBasicData(
        uint256 boxId_
    ) external view returns (Status, uint256, uint256) {
        Status status = _getStatus(boxId_);
        return (
            status,
            _publicData[boxId_]._price,
            _publicData[boxId_]._deadline
        );
    }

    /**
     * @dev Get private data of a box
     * Uses SIWE _msgSender for read-path authentication (unchanged from original)
     */
    function getPrivateData(
        uint256 boxId_,
        bytes memory siweToken_
    ) external view returns (bytes memory) {
        address sender = _msgSenderSiwe(siweToken_);
        if (sender == address(0)) revert InvalidToken();
        Status status = _getStatus(boxId_);

        if (
            status == Status.Storing ||
            status == Status.Selling ||
            status == Status.Auctioning
        ) {
            if (sender != _minterOf(boxId_)) revert InvalidCaller();
        } else if (status == Status.Delaying || status == Status.Paid) {
            if (sender != EXCHANGE.buyerOf(boxId_)) revert InvalidCaller();
        }

        return _decrypt(boxId_);
    }

    function _decrypt(uint256 boxId_) internal view returns (bytes memory) {
        return
            Sapphire.decrypt(
                bytes32(0),
                _secretData[boxId_]._nonce,
                _secretData[boxId_]._encryptedData,
                ""
            );
    }

    // ==================================================================================================

    function _checkStatus(uint256 boxId_, Status status_) internal view {
        if (_publicData[boxId_]._status != status_) revert InvalidStatus();
    }

    function _checkIsBlacklisted(uint256 boxId_) internal view {
        if (_publicData[boxId_]._status == Status.Blacklisted)
            revert InBlacklist();
    }

    function _isDeadlineIn30days(uint256 boxId_) internal view {
        uint256 deadline = _publicData[boxId_]._deadline;
        if (
            deadline < block.timestamp || deadline > block.timestamp + 3 days // NOTE 30 days----3 days
        ) {
            revert DeadlineNotIn30days();
        }
    }

    //==================================================================================================
    //                                      Setter Functions
    //                                      Only callable by Exchange or FundManager contract
    //==================================================================================================
    function _setPrice(uint256 boxId_, uint256 price_) internal {
        if (price_ != 0) {
            _publicData[boxId_]._price = price_;
            emit PriceChanged(boxId_, price_);
        }
    }

    function setPrice(
        uint256 boxId_,
        uint256 price_
    ) external onlyProjectContract {
        _setPrice(boxId_, price_);
    }

    function _setDeadline(uint256 boxId_, uint256 deadline_) internal {
        if (deadline_ > block.timestamp) {
            _publicData[boxId_]._deadline = deadline_;
            emit DeadlineChanged(boxId_, deadline_);
        }
    }

    function _addDeadline(uint256 boxId_, uint256 seconds_) internal {
        if (seconds_ == 0) revert InvalidSeconds();
        uint256 newDeadline = _publicData[boxId_]._deadline + seconds_;
        _publicData[boxId_]._deadline = newDeadline;
        emit DeadlineChanged(boxId_, newDeadline);
    }

    function addDeadline(
        uint256 boxId_,
        uint256 seconds_
    ) external onlyProjectContract {
        _addDeadline(boxId_, seconds_);
    }

    function _setStatus(uint256 boxId_, Status status_) internal {
        if (status_ == Status.Storing) revert InvalidStatus();
        if (status_ == Status.Delaying) {
            _setDeadline(boxId_, block.timestamp + 15 days); // NOTE 365----15
        }
        if (status_ != _publicData[boxId_]._status) {
            _publicData[boxId_]._status = status_;
            emit BoxStatusChanged(boxId_, status_);
        }
    }

    function setStatus(
        uint256 boxId_,
        Status status_
    ) external onlyProjectContract {
        _setStatus(boxId_, status_);
    }

    function setBasicData(
        uint256 boxId_,
        uint256 price_,
        Status status_,
        uint256 deadline_
    ) external onlyProjectContract {
        _setPrice(boxId_, price_);
        _setStatus(boxId_, status_);
        _setDeadline(boxId_, deadline_);
    }

    // ==========================================================================================================
    //                                                 publish Functions
    // ==========================================================================================================

    /**
     * @dev Publish TruthBox by minter.
     * NOTE [ERC-2771]: msg.sender -> _msgSender()
     */
    function publishByMinter(uint256 boxId_) external {
        if (_msgSender() != _secretData[boxId_]._minter) revert InvalidCaller();
        _checkStatus(boxId_, Status.Storing);
        _setStatus(boxId_, Status.Published);
    }

    /**
     * @dev Publish TruthBox by buyer.
     * NOTE [ERC-2771]: msg.sender -> _msgSender()
     */
    function publishByBuyer(uint256 boxId_) external {
        if (_msgSender() != EXCHANGE.buyerOf(boxId_)) revert NotBuyer();
        _checkStatus(boxId_, Status.Delaying);

        _setStatus(boxId_, Status.Published);
    }

    // ==========================================================================================================
    //                                               Blacklist Functions
    // ==========================================================================================================

    function addBoxToBlacklist(uint256 boxId_) external onlyDAO {
        _minterOf(boxId_);

        _checkIsBlacklisted(boxId_);

        if (EXCHANGE.buyerOf(boxId_) != address(0)) {
            EXCHANGE.setRefundPermit(boxId_, true);
        }
        Status status = _publicData[boxId_]._status;
        if (status != Status.Published && status != Status.Delaying) {
            NFT.burn(boxId_);
        }
        _publicData[boxId_]._status = Status.Blacklisted;

        emit BoxStatusChanged(boxId_, Status.Blacklisted);
    }

    function isInBlacklist(uint256 boxId_) public view returns (bool) {
        return _publicData[boxId_]._status == Status.Blacklisted;
    }

    // ==========================================================================================================
    //                                                delay function
    // ==========================================================================================================

    /**
     * @dev Extend deadline by minter.
     * NOTE [ERC-2771]: msg.sender -> _msgSender()
     */
    function extendDeadline(uint256 boxId_, uint256 time_) external {
        if (_msgSender() != _minterOf(boxId_)) revert InvalidCaller();
        _checkStatus(boxId_, Status.Storing);
        _isDeadlineIn30days(boxId_);
        if (time_ > 15 days) revert InvalidPeriod(); // NOTE: 365----15

        _addDeadline(boxId_, time_);
    }

    /**
     * @dev Internal delay logic.
     * NOTE [ERC-2771]: msg.sender -> _msgSender() for payDelayFee caller
     */
    function _delay(uint256 boxId_) private {
        uint256 amount = _publicData[boxId_]._price;

        FUND_MANAGER.payDelayFee(boxId_, _msgSender(), amount); // ERC-2771: use real sender

        uint256 newPrice = (amount * _incrementRate) / 100;
        _setPrice(boxId_, newPrice);
        // NOTE: 365----15
        _addDeadline(boxId_, 15 days);
    }

    /**
     * @dev Delay function (user-facing).
     * NOTE [ERC-2771]: _delay uses _msgSender() internally
     */
    function delay(uint256 boxId_) external {
        _checkStatus(boxId_, Status.Delaying);
        _isDeadlineIn30days(boxId_);
        _delay(boxId_);
    }

    // ==========================================================================================================
    //                                      Getter Functions
    // ==========================================================================================================
    function _minterOf(uint256 boxId_) internal view returns (address) {
        address minter = _secretData[boxId_]._minter;
        if (minter == address(0)) revert InvalidBoxId();
        return minter;
    }

    /**
     * @notice SIWE-based _msgSender for read (view) operations.
     * @dev This is separate from the ERC-2771 _msgSender() used for write operations.
     * In Sapphire, msg.sender is zero in view calls, so SIWE token is needed.
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

    function minterOf(
        uint256 boxId_,
        bytes memory siweToken_
    ) external view returns (address) {
        address sender = _msgSenderSiwe(siweToken_);
        if (sender != _minterOf(boxId_)) revert InvalidCaller();

        return sender;
    }

    function minterOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (address) {
        return _minterOf(boxId_);
    }

    // ----------------------------------------------------------------
    //                      Debugging Functions
    // ----------------------------------------------------------------

    function minterOf_debug(uint256 boxId_) external view returns (address) {
        return _minterOf(boxId_);
    }
}
