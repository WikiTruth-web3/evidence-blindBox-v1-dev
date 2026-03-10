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

import {Error} from "@marketplace-v1/interfaces/Error.sol";
import {IAddressManager} from "@marketplace-v1/interfaces/IAddressManager.sol";
import {IUserManager} from "@marketplace-v1/interfaces/IUserManager.sol";
import {CoreContracts} from "@marketplace-v1/interfaces/IContracts.sol";
import {SiweContext} from "@siwe/SiweContext.sol";
import {IdentitySalt} from "./abstract/IdentitySalt.sol";

import {ModifierV2} from "./modifier/ModifierV2.sol";

/**
 * @title UserManager
 * @notice This contract is used to get user id
 * @dev In WikiTruth, use user ID instead of address in event, to avoid address being broadcast, protect user privacy.
 * At the same time, you can use the user ID to query user information, so as to realize the rapid lookup of the index protocol!
 * Inherits IUserManager interface to ensure consistency between interface and implementation
 */

contract UserManager is ModifierV2, IUserManager, SiweContext, IdentitySalt {
    // Key is keccak256(abi.encodePacked(address, _identitySalt))
    mapping(bytes32 => uint256) private _hashedUserIds;

    mapping(address => bool) internal _blacklist;

    uint256 internal _nextUserId;

    // =======================================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
        _nextUserId = 10000;
    }

    // =====================================================================================

    function setAddress() external onlyManager {
        _setAddress(CoreContracts.UserManager);
    }

    function initUserId() external onlyAdmin {
        if (0 == _nextUserId) {
            _nextUserId = 10000;
        }
    }

    // =====================================================================================

    function _checkInBlacklist(address user_) internal view {
        if (_blacklist[user_]) revert InBlacklist();
    }

    function _checkNotInBlacklist(address user_) internal view {
        if (!_blacklist[user_]) revert NotInBlacklist();
    }

    function getUserId(
        address user_
    ) external onlyProjectContract returns (uint256) {
        _checkInBlacklist(user_);

        // core encryption logic: generate combined hash
        bytes32 identityKey = _getIdentityKey(user_);

        // Get user ID from hashed mapping
        uint256 userId = _hashedUserIds[identityKey];
        if (userId == 0) {
            userId = _nextUserId;
            _hashedUserIds[identityKey] = userId;
            unchecked {
                _nextUserId++;
            }
        }
        return userId;
    }

    function viewUserId(
        address user_
    ) external view onlyProjectContract returns (uint256) {
        _checkInBlacklist(user_);

        // core encryption logic: generate combined hash
        bytes32 identityKey = _getIdentityKey(user_);

        // Get user ID from hashed mapping
        uint256 userId = _hashedUserIds[identityKey];
        if (userId == 0) {
            revert EmptyUserId();
        }
        return userId;
    }

    /**
     * @dev Get my user id
     * @param siweToken_ SIWE token
     */
    function myUserId(bytes memory siweToken_) public view returns (uint256) {
        address sender = msg.sender;
        if (sender == address(0)) {
            // Use SiweContext get sender
            sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        }
        _checkInBlacklist(sender);

        bytes32 identityKey = _getIdentityKey(sender);
        return _hashedUserIds[identityKey];
    }

    // =====================================================================================

    //
    function addBlacklist(address user_) external onlyAdminDAO {
        _checkInBlacklist(user_);
        _blacklist[user_] = true;
        emit Blacklist(user_, true);
    }

    function removeBlacklist(address user_) external onlyAdminDAO {
        _checkNotInBlacklist(user_);
        _blacklist[user_] = false;
        emit Blacklist(user_, false);
    }

    function isBlacklisted(address user_) external view returns (bool) {
        return _blacklist[user_];
    }
}
