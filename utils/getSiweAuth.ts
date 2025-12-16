// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Signer, Signature } from 'ethers';
import { SiweMessage } from 'siwe';
import '@nomicfoundation/hardhat-chai-matchers';

/**
 * SIWE配置接口
 */
interface SiweConfig {
    chainId: number;
    version: string;
    defaultStatement: string;
    defaultExpirationHours: number;
}

/**
 * SIWE消息参数接口
 */
export interface SiweMessageParams {
    domain: string;
    signer: Signer;
    expiration?: Date;
    chainId?: number;
    statement?: string;
    resources?: string[];
    uri?: string;
    nonce?: string;
    issuedAt?: Date;
    notBefore?: Date;
}

// TODO 新增：多个域名配置
const primaryDomain: string = "primary.example.com";
const domain1: string = "app.example.com";
const domain2: string = "api.example.com";
const domain3: string = "test.example.com";
const domain4: string = "dev.example.com";
// 无效的域名，用于测试无效域名登录
const invalidDomain: string = "invalid.notallowed.com";

const domainTest: string = "domainsfs.example.com";
const domainTest2: string = "newOther.example.com";

export const domainList: string[] = [primaryDomain, domain1, domain2, domain3, domain4, invalidDomain, domainTest, domainTest2];

/**
 * 支持的测试网络配置
 */
const SUPPORTED_NETWORKS: Record<number, SiweConfig> = {
    23293: { // sapphire_localnet
        chainId: 23293,
        version: '1',
        defaultStatement: 'I accept the WikiTruth Terms of Service',
        defaultExpirationHours: 24
    },
    23294: { // sapphire_testnet
        chainId: 23294,
        version: '1',
        defaultStatement: 'I accept the WikiTruth Terms of Service',
        defaultExpirationHours: 24
    },
    23295: { // sapphire_mainnet
        chainId: 23295,
        version: '1',
        defaultStatement: 'I accept the WikiTruth Terms of Service',
        defaultExpirationHours: 24
    },
    31337: { // hardhat_local
        chainId: 31337,
        version: '1',
        defaultStatement: 'I accept the WikiTruth Terms of Service',
        defaultExpirationHours: 24
    }
};

/**
 * 获取网络配置
 */
const getNetworkConfig = (chainId: number): SiweConfig => {
    const config = SUPPORTED_NETWORKS[chainId];
    if (!config) {
        throw new Error(`不支持的链ID: ${chainId}。支持的链ID: ${Object.keys(SUPPORTED_NETWORKS).join(', ')}`);
    }
    return config;
};

/**
 * 验证域名格式
 */
const validateDomain = (domain: string): void => {
    if (!domain || typeof domain !== 'string') {
        throw new Error('域名不能为空且必须是字符串');
    }
    
    // 简单的域名格式验证
    const domainRegex = /^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
    if (!domainRegex.test(domain)) {
        throw new Error('域名格式无效');
    }
};

/**
 * 验证签名者
 */
const validateSigner = async (signer: Signer): Promise<string> => {
    if (!signer || typeof signer.getAddress !== 'function') {
        throw new Error('签名者无效');
    }
    
    try {
        return await signer.getAddress();
    } catch (error) {
        throw new Error(`获取签名者地址失败: ${error}`);
    }
};

/**
 * 生成SIWE消息
 * 模拟生成一个SIWE (Sign-In with Ethereum) 消息
 * 
 * @param params SIWE消息参数
 * @returns SIWE消息字符串
 */
export const siweMsg = async function (params: SiweMessageParams): Promise<string> {
    const {
        domain,
        signer,
        expiration,
        chainId,
        statement,
        resources,
        uri,
        nonce,
        issuedAt,
        notBefore
    } = params;

    console.log("🔐 生成SIWE消息...");

    try {
        // 参数验证
        validateDomain(domain);
        const signerAddress = await validateSigner(signer);
        
        // 获取网络配置
        const networkConfig = getNetworkConfig(chainId || 23293);
        
        // 设置默认过期时间
        const defaultExpiration = new Date();
        defaultExpiration.setHours(defaultExpiration.getHours() + networkConfig.defaultExpirationHours);
        
        // 构建SIWE消息
        const siweMessage = new SiweMessage({
            domain,
            address: signerAddress,
            statement: statement || networkConfig.defaultStatement,
            uri: uri || `https://${domain}`,
            version: networkConfig.version,
            chainId: chainId || networkConfig.chainId,
            expirationTime: expiration ? expiration.toISOString() : defaultExpiration.toISOString(),
            resources: resources || [],
            nonce: nonce || ethers.hexlify(ethers.randomBytes(16)),
            issuedAt: issuedAt ? issuedAt.toISOString() : new Date().toISOString(),
            notBefore: notBefore ? notBefore.toISOString() : undefined,
        });

        const message = siweMessage.toMessage();
        console.log(`✅ SIWE消息生成成功，签名者: ${signerAddress}`);
        return message;

    } catch (error) {
        console.error("❌ 生成SIWE消息失败:", error);
        throw error;
    }
};

/**
 * 生成SIWE消息（简化版本，保持向后兼容）
 */
export const siweMsgSimple = async function (
    domain: string,
    signer: Signer,
    expiration?: Date,
    chainId?: number,
    statement?: string,
    resources?: string[]
): Promise<string> {
    return siweMsg({
        domain,
        signer,
        expiration,
        chainId,
        statement,
        resources
    });
};

/**
 * 对消息进行ERC-191 "personal_sign"签名
 * 将给定的消息作为ERC-191 "personal_sign"消息进行签名
 * 
 * @param msg 要签名的消息
 * @param account 签名账户
 * @returns 签名对象
 */
export const erc191sign = async function (msg: string, account: Signer): Promise<Signature> {
    console.log("✍️ 进行ERC-191签名...");

    try {
        // 参数验证
        if (!msg || typeof msg !== 'string') {
            throw new Error('消息不能为空且必须是字符串');
        }
        
        await validateSigner(account);
        
        // 执行签名
        const signature = await account.signMessage(msg);
        const sig = ethers.Signature.from(signature);
        
        console.log(`✅ ERC-191签名成功，签名者: ${await account.getAddress()}`);
        return sig;

    } catch (error) {
        console.error("❌ ERC-191签名失败:", error);
        throw error;
    }
};

/**
 * 验证SIWE消息签名
 * 
 * @param message SIWE消息
 * @param signature 签名
 * @param expectedAddress 期望的签名者地址
 * @returns 验证结果
 */
export const verifySiweSignature = async function (
    message: string,
    signature: string,
    expectedAddress: string
): Promise<boolean> {
    try {
        const recoveredAddress = ethers.verifyMessage(message, signature);
        return recoveredAddress.toLowerCase() === expectedAddress.toLowerCase();
    } catch (error) {
        console.error("❌ SIWE签名验证失败:", error);
        return false;
    }
};

/**
 * 生成随机nonce
 */
export const generateNonce = (): string => {
    return ethers.hexlify(ethers.randomBytes(16));
};

/**
 * 获取支持的链ID列表
 */
export const getSupportedChainIds = (): number[] => {
    return Object.keys(SUPPORTED_NETWORKS).map(id => parseInt(id));
};

/**
 * 检查链ID是否支持
 */
export const isChainIdSupported = (chainId: number): boolean => {
    return chainId in SUPPORTED_NETWORKS;
};

