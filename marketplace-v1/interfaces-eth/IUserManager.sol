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

/**
 * @title IUserManager
 * @notice UserId contract interface, defining all externally exposed functions and events
 * @dev This interface serves as the top-level constraint for the UserId contract, ensuring consistency between interface and implementation
 */
interface IUserManager {
    // =====================================================================================
    //                                                  Events
    // =====================================================================================

    event Blacklist(address user, bool status);

    // =====================================================================================
    //                                          Address Management
    // =====================================================================================

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external;

    // =====================================================================================
    //                                          User ID Functions
    // =====================================================================================

    /**
     * @notice Get user ID
     * @param user_ User address
     * @return User ID
     * @dev Only callable by project contracts
     */
    function getUserId(address user_) external returns (uint256);

    /**
     * @notice view user ID (View)
     * @param user_ User address
     * @return User ID
     * @dev Only callable by project contracts
     */
    function viewUserId(address user_) external view returns (uint256);

    /**
     * @notice Get my user ID
     * @return User ID
     */
    function myUserId() external view returns (uint256);
    // =====================================================================================
    //                                          Blacklist Functions
    // =====================================================================================

    /**
     * @notice Add user to blacklist
     * @param user_ User address
     * @dev Only callable by admin or DAO
     */
    function addBlacklist(address user_) external;

    /**
     * @notice Remove user from blacklist
     * @param user_ User address
     * @dev Only callable by admin or DAO
     */
    function removeBlacklist(address user_) external;

    /**
     * @notice Check if user is blacklisted
     * @param user_ User address
     * @return Whether user is blacklisted
     */
    function isBlacklisted(address user_) external view returns (bool);
}
