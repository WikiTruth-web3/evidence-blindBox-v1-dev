// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    Sapphire
} from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import {IEncryption} from "./interfaces/IEncryption.sol";

/**
 * @title EncryptionTest - 加密测试合约
 * @dev 在Oasis Sapphire机密计算网络中存储和处理机密数据
 */
contract EncryptionTest is IEncryption {
    error EmptyNonce();
    bytes32 private immutable _contractSecret;

    // mapping: user address => their unique secret salt
    mapping(address => bytes32) private _nonces;

    mapping(address => bytes) private _encryptedData;

    // ==================================================================================================
    /**
     * @dev 构造函数
     */
    constructor(bytes memory pers_) {
        _contractSecret = bytes32(Sapphire.randomBytes(32, pers_));
    }

    function _deriveKey(bytes32 salt_) internal view returns (bytes32) {
        // 使用内置的派生函数，确保密钥与当前合约地址及根种子绑定
        return
            Sapphire.deriveSymmetricKey(
                Sapphire.Curve25519PublicKey.wrap(salt_),
                Sapphire.Curve25519SecretKey.wrap(_contractSecret)
            );
    }

    function _getNonce(address owner_) internal returns (bytes32 nonce_) {
        bytes32 nonce = _nonces[owner_];
        if (nonce == bytes32(0)) {
            nonce = bytes32(Sapphire.randomBytes(32, abi.encodePacked(owner_)));
            _nonces[owner_] = nonce;
        }
        return nonce;
    }

    /**
     * @dev 存储机密数据
     * @param owner_ 所有者地址
     * @param data_ 要存储的机密数据
     * @return encryptedData_ 加密后的数据
     */
    function encryptData(
        address owner_,
        bytes calldata data_
    ) external returns (bytes memory encryptedData_) {
        bytes32 secretKey = _deriveKey(keccak256(abi.encodePacked(owner_)));

        // 生成加密nonce（关键修复：保存nonce用于解密）
        bytes32 nonce = _getNonce(owner_);

        // 加密数据
        encryptedData_ = Sapphire.encrypt(secretKey, nonce, data_, "");

        _encryptedData[owner_] = encryptedData_;

        return encryptedData_;
    }

    /**
     * @dev 解密存储在合约中的机密数据
     * @param owner_ 所有者地址
     * @return data_ 解密后的数据
     */
    function decryptStoredData(
        address owner_
    ) external view returns (bytes memory data_) {
        bytes32 secretKey = _deriveKey(keccak256(abi.encodePacked(owner_)));

        bytes32 nonce = _nonces[owner_];
        if (nonce == bytes32(0)) revert EmptyNonce();
        return Sapphire.decrypt(secretKey, nonce, _encryptedData[owner_], "");
    }

    /**
     * @dev 解密数据 (实现 IEncryption 接口)
     * @param owner_ 所有者地址
     * @param encryptedData_ 加密后的数据
     * @return data_ 解密后的数据
     */
    function decryptData(
        address owner_,
        bytes calldata encryptedData_
    ) external view returns (bytes memory data_) {
        bytes32 secretKey = _deriveKey(keccak256(abi.encodePacked(owner_)));

        bytes32 nonce = _nonces[owner_];
        if (nonce == bytes32(0)) revert EmptyNonce();

        return Sapphire.decrypt(secretKey, nonce, encryptedData_, "");
    }
}
