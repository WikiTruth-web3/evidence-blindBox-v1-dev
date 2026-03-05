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

import {TruthBox02} from "./base/TruthBox02.sol";
import {Status} from "@marketplace-v1/interfaces/ITruthBox.sol";

/**
 *  @notice TruthBox contract
 *  Implement basic TruthBox functions, including mint, publish, blacklist, etc.
 *  Also includes important transaction-related functions, including setPrice, setDeadline, addDeadline, setStatus
 *  @dev Inherits ITruthBox interface to ensure consistency between interface and implementation
 */

contract TruthBox is TruthBox02 {
    // ==================================================================================================
    constructor(
        address addrManager_,
        address trustedForwarder_
    ) TruthBox02(addrManager_, trustedForwarder_) {}

    // ==========================================================================================================
    //                                                 mint Functions
    // ==========================================================================================================

    /**
     * @dev Create a truth box
     * @param tokenCID_ The CID of the token
     * @param boxInfoCID_ The CID of the box info
     * @param key_ The key of the box
     * @param price_ The price of the box
     * @return The ID of the box
     */
    function create(
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

        emit PriceChanged(boxId, price_);
        emit DeadlineChanged(boxId, deadline);
        // Log the price and deadline, do not record status, because status is Storing status

        return boxId;
    }

    function createAndPublish(
        string calldata tokenCID_,
        string calldata boxInfoCID_
    ) external returns (uint256) {
        _checkCID(tokenCID_, boxInfoCID_);

        uint256 boxId = _setBoxData(boxInfoCID_, 0, Status.Published, 0, "");

        emit BoxStatusChanged(boxId, Status.Published);
        return boxId;
    }

    //==================================================================================================
    //                                      Setter Functions
    //==================================================================================================

    function setPrice(
        uint256 boxId_,
        uint256 price_
    ) external onlyProjectContract {
        _setPrice(boxId_, price_);
    }

    function addDeadline(
        uint256 boxId_,
        uint256 seconds_
    ) external onlyProjectContract {
        _addDeadline(boxId_, seconds_);
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
    //                                                delay function
    // ==========================================================================================================

    // Safe payment, NFT must not be public and invalid
    function delay(uint256 boxId_) external {
        _checkStatus(boxId_, Status.Delaying);
        _isDeadlineIn30days(boxId_);
        _delay(boxId_);
    }

    // ==========================================================================================================
    //                                                 public Functions
    // ==========================================================================================================

    /**
     * @dev Publish TruthBox, which minter can call,
     * If the minter wants to publish, it must be Storing status.
     */
    function publishByMinter(uint256 boxId_) external {
        // erc2771 - _msgSender() is the real caller
        if (_msgSender() != _secretData[boxId_]._minter) revert InvalidCaller();
        _checkStatus(boxId_, Status.Storing);
        _setStatus(boxId_, Status.Published);
    }

    /**
     * @dev Publish TruthBox, which administrators can call,
     * If the buyer wants to publish, it must be Delaying status.
     */
    function publishByBuyer(uint256 boxId_) external {
        // erc2771 - _msgSender() is the real caller
        if (_msgSender() != EXCHANGE.buyerOf(boxId_)) revert NotBuyer();
        _checkStatus(boxId_, Status.Delaying);

        _setStatus(boxId_, Status.Published);
    }
}
