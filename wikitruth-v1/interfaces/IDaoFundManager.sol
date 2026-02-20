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
 * @title IDaoFundManager
 * @notice DaoFundManager contract interface, defining all externally exposed functions and events
 * @dev This interface serves as the top-level constraint for the DaoFundManager contract, ensuring consistency between interface and implementation
 */
interface IDaoFundManager {
    // =====================================================================================
    //                                                  Events
    // =====================================================================================

    event ExtendsFeePaid(uint256 indexed userId, uint256 amount);

    // =====================================================================================
    //                                          Address Management
    // =====================================================================================

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external;

    // =====================================================================================
    //                                          Payment Functions (Project Contracts Only)
    // =====================================================================================

    /**
     * @notice Pay order amount
     * @param buyer_ Buyer address
     * @param amount_ Amount to pay
     * @dev Only callable by project contracts
     */
    function receiveExtendsFee(address sender_, uint256 amount_) external;

    // =====================================================================================
    //                                          Withdrawal Functions
    // =====================================================================================

    /**
     * @notice Withdraw extends fee
     */
    function withdrawExtendsFee(uint256 amount_) external;

    /**
     * @notice Get extends fee amount
     * @return extends fee amount
     */
    function extendsFeeAmounts() external view returns (uint256);
}
