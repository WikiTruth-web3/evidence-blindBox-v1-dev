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
    Sapphire
} from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

/**
 * @title IdentitySalt
 * @notice Abstract base class: provides privacy hashing capability for child contracts
 */

abstract contract IdentitySalt {
    // Secret salt to decouple addresses from User IDs
    bytes32 private _identitySalt;

    // =======================================================================================================
    constructor() {
        // Initialize the cryptographically secure random salt
        if (_identitySalt == bytes32(0)) {
            _identitySalt = bytes32(
                Sapphire.randomBytes(32, "WikiTruth Identity")
            );
        }
    }

    // =====================================================================================

    /**
     * @dev Core logic: convert address to irreversible privacy hash
     */
    function _getIdentityKey(address user_) internal view returns (bytes32) {
        if (user_ == address(0)) return bytes32(0);
        // If the salt is not initialized, it may cause an error or return an unsafe result. It is recommended to add a security check
        require(_identitySalt != bytes32(0), "IdentitySalt: Not initialized");
        return keccak256(abi.encodePacked(user_, _identitySalt));
    }
}
