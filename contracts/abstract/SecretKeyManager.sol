// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {
    Sapphire
} from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

/**
 * @title SecretKeyManager
 * @notice Abstract base class: provides privacy key derivation for data encryption
 */
abstract contract SecretKeyManager {
    error EmptyContractSecret();

    // Contract-private root secret for data encryption
    // Unlike _identitySalt, this is used for symmetric key derivation
    bytes32 private _contractSecret;

    constructor(bytes memory pers_) {
        if (_contractSecret == bytes32(0)) {
            _contractSecret = bytes32(Sapphire.randomBytes(32, pers_));
        }
    }

    /**
     * @dev Derive a unique symmetric key for a specific context (e.g., boxId)
     * @param salt_ A context-specific salt (like bytes32(boxId))
     */
    function _deriveDataKey(bytes32 salt_) internal view returns (bytes32) {
        if (_contractSecret == bytes32(0)) revert EmptyContractSecret();

        // Derive a key that is bound to this contract and the specific salt
        return
            Sapphire.deriveSymmetricKey(
                Sapphire.Curve25519PublicKey.wrap(salt_),
                Sapphire.Curve25519SecretKey.wrap(_contractSecret)
            );
    }
}
