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

import {
    SignatureRSV
} from "@oasisprotocol/sapphire-contracts/contracts/auth/A13e.sol";

interface ISiweAuth {
    /**
     * @notice Use SIWE message and signature to login
     * @param siweMsg The signed SIWE message
     * @param sig The signature of the SIWE message
     * @return authToken_ The encrypted authentication token
     */
    function login(
        string calldata siweMsg,
        SignatureRSV calldata sig
    ) external view returns (bytes memory authToken_);

    function getMsgSender(bytes memory token_) external view returns (address);

    /**
     * @dev Check if the domain is valid
     * @param domainToCheck The domain to check
     * @return Whether the domain is valid
     */
    function isDomainValid(
        string calldata domainToCheck
    ) external view returns (bool);

    /**
     * @dev Set the new admin
     * @param newAdmin The new admin address
     */
    function setAdmin(address newAdmin) external;

    /**
     * @dev Check if the session is valid
     * @param token The authentication token
     * @return Whether the session is valid
     */
    function isSessionValid(bytes memory token) external view returns (bool);

    /**
     * @notice Return the domain associated with the dApp (return the main domain, keep backward compatibility)
     * @return The domain string
     */
    function domain() external view returns (string memory);

    /**
     * @dev Get all supported domains
     * @return The domain array
     */
    function allDomains() external view returns (string[] memory);
}
