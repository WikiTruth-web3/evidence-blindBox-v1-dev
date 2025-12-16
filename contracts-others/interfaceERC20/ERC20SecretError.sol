// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

interface ERC20SecretError {
    /// 无效的授权标签
    error InvalidPermitLabel();
    /// 无效的授权金额
    error InvalidPermitAmount();
    /// EIP错误
    error EIPError();
    /// 零金额
    error ZeroAmount();
    /// 签名已使用
    error SignatureUsed();
    /// 余额不足
    error InsufficientBalance();
    /// 过期截止时间
    error ExpiredDeadline();

    /// 无效的签名
    error InvalidSignature();


}