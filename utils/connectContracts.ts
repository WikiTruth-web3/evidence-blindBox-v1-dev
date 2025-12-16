// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Signer, Contract } from 'ethers';
import { SiweMessage } from 'siwe';
import '@nomicfoundation/hardhat-chai-matchers';
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { NETWORKS } from '@oasisprotocol/sapphire-paratime';

/**
 * 链接地址到合约实例
 * 为每个地址创建独立的合约连接，避免修改原始合约实例
 */

export const connectContracts = async function <T extends Contract>(
    contractFactory: () => T,
    addresses: Signer[]
): Promise<T[]> {
    console.log("🚀 开始链接地址到合约...");

    // 参数验证
    if (!contractFactory || typeof contractFactory !== 'function') {
        throw new Error("contractFactory 必须是一个返回合约实例的函数");
    }
    
    if (!addresses || !Array.isArray(addresses) || addresses.length === 0) {
        throw new Error("addresses 必须是一个非空的地址数组");
    }

    const connectedContracts: T[] = [];

    try {
        for (let i = 0; i < addresses.length; i++) {
            const signer = addresses[i];
            
            // 验证签名者
            if (!signer || typeof signer.getAddress !== 'function') {
                throw new Error(`地址索引 ${i} 不是有效的签名者`);
            }

            // 为每个地址创建新的合约实例
            const contract = contractFactory();
            const connectedContract = contract.connect(signer) as T;
            connectedContracts.push(connectedContract);
            
            console.log(`✅ 已连接地址 ${i + 1}/${addresses.length}: ${await signer.getAddress()}`);
        }

        console.log(`🎉 成功连接 ${connectedContracts.length} 个合约实例`);
        return connectedContracts;

    } catch (error) {
        console.error("❌ 连接合约时发生错误:", error);
        throw error;
    }
}

/**
 * 连接单个合约到指定地址
 */
export const connectContract = async function <T extends Contract>(
    contract: T,
    signer: Signer
): Promise<T> {
    if (!contract) {
        throw new Error("合约实例不能为空");
    }
    
    if (!signer || typeof signer.getAddress !== 'function') {
        throw new Error("签名者无效");
    }

    try {
        const connectedContract = contract.connect(signer) as T;
        console.log(`✅ 合约已连接到地址: ${await signer.getAddress()}`);
        return connectedContract;
    } catch (error) {
        console.error("❌ 连接合约时发生错误:", error);
        throw error;
    }
}
    
