// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {Error} from "@interfaces/Error.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IUserManager} from "@interfaces/eth/IUserManager.sol";
import {ModifierV2} from "./modifier/ModifierV2.sol";
import {CoreContracts} from "@interfaces/IContracts.sol";

/**
 * @title UserManager
 * @dev This contract is used to get user id
 * In WikiTruth, use user ID instead of address in event, to avoid address being broadcast, protect user privacy.
 * At the same time, you can use the user ID to query user information, so as to realize the rapid lookup of the index protocol!
 */

contract UserManager is ModifierV2, IUserManager {
    // =====================================================================================

    mapping(address => bool) internal _blacklist;

    // =======================================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {}

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

    /**
     * @dev get user id
     * @param user_ The address of user
     * Only callable by the contracts in the project (access)
     */
    function getUserId(
        address user_
    ) external view onlyProjectContract returns (bytes32) {
        _checkInBlacklist(user_);
        return bytes32(uint256(uint160(user_)));
    }

    /**
     * @dev Get my user id
     * NOTE In sapphire, you need to comment, use the myUserId(bytes memory token_) function above
     */
    function myUserId() public view returns (bytes32) {
        address sender = msg.sender;
        _checkInBlacklist(sender);
        return bytes32(uint256(uint160(sender)));
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
