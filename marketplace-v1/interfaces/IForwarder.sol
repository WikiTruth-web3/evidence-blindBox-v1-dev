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

pragma solidity ^0.8.20;

/**
 * @title IForwarder
 * @dev Has enhanced control functions ERC-2771 forwarder.
 * Includes: relayer whitelist, target contract whitelist, gas limit and emergency pause function.
 * This contract is specifically used to handle meta-transactions, using EIP-712 signatures.
 */
interface IForwarder {
    // =====================================================================================
    //                                  System Configuration
    // =====================================================================================

    /**
     * @notice Initialize contract references
     */
    function setAddress() external;

    // =====================================================================================
    //                                  Management Functions
    // =====================================================================================

    /**
     * @notice Set target contract whitelist status
     */
    // function setTargetStatus(address target_, bool status_) external;

    /**
     * @notice Set gas limit per transaction
     */
    // function setMaxGasLimit(uint256 maxGasLimit_) external;

    /**
     * @notice pause status
     */
    // function pause() external;

    /**
     * @notice unpause status
     */
    // function unpause() external;

    // =====================================================================================
    //                                     Getters
    // =====================================================================================

    function isTargetWhitelisted(address target_) external view returns (bool);

    function getMaxGasLimit() external view returns (uint256);
}
