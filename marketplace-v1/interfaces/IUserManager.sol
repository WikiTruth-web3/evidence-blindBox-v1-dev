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
 * @notice UserManager contract interface, defining all externally exposed functions and events
 * @dev This interface serves as the top-level constraint for the UserManager contract, ensuring consistency between interface and implementation
 */
interface IUserManager {
    // =====================================================================================
    //                                                  Events
    // =====================================================================================

    event Blacklisted(address user, bool status);

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
    function getUserId(address user_) external view returns (bytes32);

    /**
     * @notice Get my user ID
     * @param siweToken_ SIWE token
     * @return User ID
     */
    function myUserId(bytes memory siweToken_) external view returns (bytes32);

    // =====================================================================================
    //                                          Blacklisted Functions
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
