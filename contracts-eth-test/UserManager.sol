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
import {
    IAddressManager
} from "@marketplace-v1/interfaces-eth/IAddressManager.sol";
import {IUserManager} from "@marketplace-v1/interfaces-eth/IUserManager.sol";
import {ModifierV2} from "./modifier/ModifierV2.sol";
import {CoreContracts} from "@marketplace-v1/interfaces/IContracts.sol";

/**
 * @title UserManager
 * @dev This contract is used to get user id
 * In WikiTruth, use user ID instead of address in event, to avoid address being broadcast, protect user privacy.
 * At the same time, you can use the user ID to query user information, so as to realize the rapid lookup of the index protocol!
 */

contract UserManager is ModifierV2, IUserManager {
    // =====================================================================================

    mapping(address => uint256) internal _userIds;
    mapping(address => bool) internal _blacklist;

    uint256 internal _nextUserId;

    // =======================================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
        // ADDR_MANAGER = IAddressManager(addrManager_);
        _nextUserId = 10000;
    }

    // =====================================================================================

    function setAddress() external onlyManager {
        _setAddress(CoreContracts.UserManager);
    }

    // =====================================================================================

    /**
     * @dev Get user id
     * @param user_ The address of user
     * Only callable by the contracts in the project (access)
     */
    function getUserId(
        address user_
    ) external onlyProjectContract returns (uint256) {
        if (_blacklist[user_]) revert InBlacklist();
        // Get user ID
        uint256 userId = _userIds[user_];
        if (userId == 0) {
            _userIds[user_] = _nextUserId;
            unchecked {
                _nextUserId++;
            }
            return _nextUserId; // Return new allocated ID
        }
        return userId; // Return existing ID
    }

    /**
     * @dev Get my user id
     * NOTE In sapphire, you need to comment, use the myUserId(bytes memory token_) function above
     */
    function myUserId() public view returns (uint256) {
        address sender = msg.sender;
        if (_blacklist[sender]) revert InBlacklist();
        return _userIds[sender];
    }

    // =====================================================================================

    //
    function addBlacklist(address user_) external onlyAdminDAO {
        if (_blacklist[user_]) revert InBlacklist();
        _blacklist[user_] = true;
        emit Blacklist(user_, true);
    }

    function removeBlacklist(address user_) external onlyAdminDAO {
        if (!_blacklist[user_]) revert NotInBlacklist();
        _blacklist[user_] = false;
        emit Blacklist(user_, false);
    }

    function isBlacklisted(address user_) external view returns (bool) {
        return _blacklist[user_];
    }
}
