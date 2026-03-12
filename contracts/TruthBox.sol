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

import {TruthBox03} from "./base/TruthBox03.sol";
import {ITruthBox, Status} from "@marketplace-v1/interfaces/ITruthBox.sol";
import {CoreContracts} from "@marketplace-v1/interfaces/IContracts.sol";

/**
 *  @notice TruthBox contract
 *  Implement basic TruthBox functions, including mint, publish, blacklist, etc.
 *  Also includes important transaction-related functions, including setPrice, setDeadline, addDeadline, setStatus
 *  @dev Inherits ITruthBox interface to ensure consistency between interface and implementation
 */

contract TruthBox is TruthBox03, ITruthBox {
    // ==================================================================================================
    constructor(
        address addrManager_,
        address trustedForwarder_,
        bytes memory pers_
    ) TruthBox03(addrManager_, trustedForwarder_, pers_) {}

    function setAddress() external onlyManager {
        _setAddress(CoreContracts.TruthBox);
    }

    // ==========================================================================================================
    //                                                 mint Functions
    // ==========================================================================================================

    function create(
        string calldata tokenCID_,
        string calldata boxInfoCID_,
        bytes calldata key_,
        uint256 price_
    ) external returns (uint256) {
        return _create(tokenCID_, boxInfoCID_, key_, price_);
    }

    function createAndPublish(
        string calldata tokenCID_,
        string calldata boxInfoCID_
    ) external returns (uint256) {
        return _createAndPublish(tokenCID_, boxInfoCID_);
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
    function extendDeadline(uint256 boxId_, uint256 time_) external {
        _extendDeadline(boxId_, time_);
    }

    // Safe payment, NFT must not be public and invalid
    function delay(uint256 boxId_) external {
        _checkStatus(boxId_, Status.Delaying);
        _isInWindowPeriod(boxId_);
        _delay(boxId_);
    }

    // ==========================================================================================================
    //                                                 public Functions
    // ==========================================================================================================

    function publishByMinter(uint256 boxId_) external {
        _checkMinter(boxId_);
        _checkStatus(boxId_, Status.Storing);
        _setStatus(boxId_, Status.Published);
    }

    function publishByBuyer(uint256 boxId_) external {
        _checkBuyer(boxId_);
        _checkStatus(boxId_, Status.Delaying);
        _setStatus(boxId_, Status.Published);
    }

    // ==========================================================================================================
    //                                                getter Functions
    // ==========================================================================================================

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

    function getSecretData(
        uint256 boxId_,
        bytes memory siweToken_
    ) external view returns (bytes memory) {
        return _getSecretData(boxId_, siweToken_);
    }

    // ==========================================================================================================

    function minterIdOf(
        uint256 boxId_
    ) external view onlyProjectContract returns (bytes32) {
        return _minterIdOf(boxId_);
    }

    // ==========================================================================================================
    function addToBlacklist(uint256 boxId_) external onlyDAO {
        _addToBlacklist(boxId_);
    }

    function isInBlacklist(uint256 boxId_) public view returns (bool) {
        return _basicData[boxId_]._status == Status.Blacklisted;
    }
}
