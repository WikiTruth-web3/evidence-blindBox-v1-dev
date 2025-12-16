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


import {Error} from "@wikitruth-v1/interfaces/interfaceError.sol";
import {ISiweAuth} from "./interfaces2/ISiweAuth.sol";
import {IAddressManager} from "@wikitruth-v1/interfaces/IAddressManager.sol";
import {IUserId} from "@wikitruth-v1/interfaces/IUserId.sol";

import {Modifier} from "./abstract/Modifier.sol";

/**
 * @title UserId
 * @notice This contract is used to get user id
 * @dev In WikiTruth, use user ID instead of address in event, to avoid address being broadcast, protect user privacy.
 * At the same time, you can use the user ID to query user information, so as to realize the rapid lookup of the index protocol!
 * Inherits IUserId interface to ensure consistency between interface and implementation
 */

contract UserId is Modifier, IUserId {
    error Blacklisted();
    error NotBlacklisted();

    // =====================================================================================

    address internal TRUTH_BOX;
    address internal FUND_MANAGER;
    address internal EXCHANGE;
    address internal SIWE_AUTH;

    mapping(address => uint256) internal _userIds;
    mapping(address => bool) internal _blacklist;
    
    uint256 internal _currentUserId;
    
    // =======================================================================================================
    constructor(address addrManager_) Modifier(addrManager_) {
        _currentUserId = 10000;
    }

    // =====================================================================================

    function setAddress() external checkSetCaller {
        IAddressManager addrMgr = ADDR_MANAGER;

        address truthBox = addrMgr.truthBox();
        address exchange = addrMgr.exchange();
        address fundManager = addrMgr.fundManager();
        address siweAuth = addrMgr.siweAuth();

        if (truthBox != address(0) && truthBox != TRUTH_BOX){
            TRUTH_BOX = truthBox;
        }
        if (exchange != address(0) && exchange != EXCHANGE){
            EXCHANGE = exchange;
        }
        if (fundManager != address(0) && fundManager != FUND_MANAGER){
            FUND_MANAGER = fundManager;
        }
        if (siweAuth != address(0) && siweAuth != SIWE_AUTH){
            SIWE_AUTH = siweAuth;
        }
    }

    // =====================================================================================

    /**
     * @dev Get user id
     * @param user_ The address of user
     * Only callable by the contracts in the project (access)
     */
    function getUserId(address user_) external onlyProjectContract returns (uint256) {

        if (_blacklist[user_]) revert Blacklisted();
        // Get user ID
        uint256 userId = _userIds[user_];
        if (userId == 0) {
            uint256 id = _currentUserId;
            
            _userIds[user_] = id;
            unchecked {
                _currentUserId++;
            }
            return id; // Return new allocated ID
        }
        return userId; 
    }

    /**
     * @dev Get my user id
     * @param token_ SIWE token
     */
    function myUserId(bytes memory token_) public view returns (uint256) {

        address sender = msg.sender;
        if (sender == address(0)) {
            sender = ISiweAuth(SIWE_AUTH).getMsgSender(token_);
        }
        if (_blacklist[sender]) revert Blacklisted();
        return _userIds[sender];
    }

    // =====================================================================================

    //
    function addBlacklist(address user_) external onlyAdminDAO {
        if (_blacklist[user_]) revert Blacklisted();
        _blacklist[user_] = true;
        emit Blacklist(user_, true);
    }

    function removeBlacklist(address user_) external onlyAdminDAO {
        if (!_blacklist[user_]) revert NotBlacklisted();
        _blacklist[user_] = false;
        emit Blacklist(user_, false);
    }

    function isBlacklisted(address user_) external view returns (bool) {
        return _blacklist[user_];
    }


}
