// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {Error} from "@interfaces/Error.sol";
import {IAddressManager} from "@interfaces/sapphire/IAddressManager.sol";
import {IUserManager} from "@interfaces/sapphire/IUserManager.sol";
import {CoreContracts} from "@interfaces/IContracts.sol";
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
    mapping(address => bool) internal _blacklist;

    // =======================================================================================================
    constructor(
        address addrManager_,
        bytes memory pers_
    ) ModifierV2(addrManager_) IdentitySalt(pers_) {}

    // =====================================================================================

    function setAddress() external onlyManager {
        _setAddress(CoreContracts.UserManager);
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
    ) external view onlyProjectContract returns (bytes32) {
        _checkInBlacklist(user_);

        // core encryption logic: generate combined hash
        return _getUserId(user_);
    }

    function myUserId(bytes memory siweToken_) public view returns (bytes32) {
        address sender = msg.sender;
        if (sender == address(0)) {
            // Use SiweContext get sender
            sender = _msgSenderSiwe(SIWE_AUTH, siweToken_);
        }
        _checkInBlacklist(sender);

        return _getUserId(sender);
    }

    // =====================================================================================

    //
    function addBlacklist(address user_) external onlyAdminDAO {
        _checkInBlacklist(user_);
        _blacklist[user_] = true;
        emit Blacklisted(user_, true);
    }

    function removeBlacklist(address user_) external onlyAdminDAO {
        _checkNotInBlacklist(user_);
        _blacklist[user_] = false;
        emit Blacklisted(user_, false);
    }

    function isBlacklisted(address user_) external view returns (bool) {
        return _blacklist[user_];
    }
}
