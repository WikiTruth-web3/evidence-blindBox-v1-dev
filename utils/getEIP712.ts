import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Signer, Signature } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";

/**
 * EIP712许可类型枚举
 */
export enum PermitType {
    View = 0,
    Transfer = 1,
    Approve = 2
}

/**
 * EIP712域配置接口
 */
export interface EIP712Domain {
    name: string;
    version: string;
    chainId: number;
    verifyingContract: string;
}

/**
 * EIP712许可参数接口
 */
export interface EIP712PermitParams {
    signer: Signer;
    spender: Signer | string;
    amount: bigint | number;
    mode: PermitType;
    contractAddress: string;
    domainName: string;
    network?: any;
    customDeadline?: number;
    domainVersion?: string;
}

/**
 * EIP712许可结果接口
 */
export interface EIP712PermitResult {
    label: PermitType;
    owner: string;
    spender: string;
    amount: bigint;
    deadline: number;
    signature: {
        r: string;
        s: string;
        v: number;
    };
    domain: EIP712Domain;
}

/**
 * 网络配置接口
 */
interface NetworkConfig {
    chainId: number;
    name: string;
    defaultDomainName: string;
    defaultDomainVersion: string;
}

/**
 * 支持的测试网络配置
 */
const SUPPORTED_NETWORKS: Record<number, NetworkConfig> = {
    23293: { // sapphire_localnet
        chainId: 23293,
        name: "sapphire_localnet",
        defaultDomainName: "Private Token",
        defaultDomainVersion: "1"
    },
    23294: { // sapphire_testnet
        chainId: 23294,
        name: "sapphire_testnet",
        defaultDomainName: "Private Token",
        defaultDomainVersion: "1"
    },
    23295: { // sapphire_mainnet
        chainId: 23295,
        name: "sapphire_mainnet",
        defaultDomainName: "Private Token",
        defaultDomainVersion: "1"
    },
    31337: { // hardhat_local
        chainId: 31337,
        name: "hardhat_local",
        defaultDomainName: "Private Token",
        defaultDomainVersion: "1"
    }
};

/**
 * 获取网络配置
 */
const getNetworkConfig = (chainId: number): NetworkConfig => {
    const config = SUPPORTED_NETWORKS[chainId];
    if (!config) {
        throw new Error(`不支持的链ID: ${chainId}。支持的链ID: ${Object.keys(SUPPORTED_NETWORKS).join(', ')}`);
    }
    return config;
};

/**
 * 验证地址格式
 */
const validateAddress = (address: string, name: string): void => {
    if (!address || typeof address !== 'string') {
        throw new Error(`${name} 地址不能为空且必须是字符串`);
    }

    if (!ethers.isAddress(address)) {
        throw new Error(`${name} 地址格式无效: ${address}`);
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
 * 获取地址字符串
 */
const getAddressString = async (addressOrSigner: Signer | string): Promise<string> => {
    if (typeof addressOrSigner === 'string') {
        validateAddress(addressOrSigner, '地址');
        return addressOrSigner;
    } else {
        return await validateSigner(addressOrSigner);
    }
};

/**
 * 创建EIP712域配置
 */
const createEIP712Domain = (
    contractAddress: string,
    chainId: number,
    domainName: string,
    domainVersion?: string
): EIP712Domain => {
    const networkConfig = getNetworkConfig(chainId);

    return {
        name: domainName || networkConfig.defaultDomainName,
        version: domainVersion || networkConfig.defaultDomainVersion,
        chainId: chainId,
        verifyingContract: contractAddress
    };
};

/**
 * 生成EIP712许可签名
 * 为私有代币创建EIP712许可签名
 * 
 * @param params EIP712许可参数
 * @returns EIP712许可结果
 */
export const createEIP712Permit_PrivateToken = async function (
    params: EIP712PermitParams
): Promise<EIP712PermitResult> {
    const {
        signer,
        spender,
        amount,
        mode,
        contractAddress,
        network: networkParam,
        customDeadline,
        domainName,
        domainVersion
    } = params;

    console.log("🔐 生成EIP712许可签名...");

    try {
        // 参数验证
        const signerAddress = await validateSigner(signer);
        const spenderAddress = await getAddressString(spender);

        validateAddress(contractAddress, '合约');

        // 验证金额
        if (amount < 0) {
            throw new Error('金额不能为负数');
        }

        // 验证许可类型
        if (!Object.values(PermitType).includes(mode)) {
            throw new Error(`无效的许可类型: ${mode}`);
        }

        // 获取链ID
        const chainId = networkParam?.chainId || (await ethers.provider.getNetwork()).chainId;

        // 创建域配置
        const domain = createEIP712Domain(contractAddress, Number(chainId), domainName, domainVersion);

        // 设置截止时间
        const deadline = customDeadline || Math.floor(Date.now() / 1000) + 3600; // 默认1小时后过期

        // EIP712类型定义
        const types = {
            EIP712Permit: [
                { name: "label", type: "uint8" }, // PermitType枚举对应uint8
                { name: "owner", type: "address" },
                { name: "spender", type: "address" },
                { name: "amount", type: "uint256" },
                { name: "deadline", type: "uint256" }
            ]
        };

        // 签名值
        const value = {
            label: mode,
            owner: signerAddress,
            spender: spenderAddress,
            amount: BigInt(amount),
            deadline: deadline
        };

        console.log(`📝 签名参数:`, {
            owner: signerAddress,
            spender: spenderAddress,
            amount: amount.toString(),
            mode: PermitType[mode],
            deadline: new Date(deadline * 1000).toISOString()
        });

        // 执行EIP712签名
        const signature = await signer.signTypedData(domain, types, value);
        const sig = ethers.Signature.from(signature);

        const result: EIP712PermitResult = {
            label: mode,
            owner: signerAddress,
            spender: spenderAddress,
            amount: BigInt(amount),
            deadline: deadline,
            signature: {
                r: sig.r,
                s: sig.s,
                v: sig.v
            },
            domain: domain
        };

        console.log(`✅ EIP712许可签名生成成功`);
        return result;

    } catch (error) {
        console.error("❌ EIP712许可签名生成失败:", error);
        throw error;
    }
};


/**
 * 验证EIP712签名
 * 
 * @param domain EIP712域配置
 * @param types 类型定义
 * @param value 签名值
 * @param signature 签名
 * @param expectedAddress 期望的签名者地址
 * @returns 验证结果
 */
export const verifyEIP712Signature = async function (
    domain: EIP712Domain,
    types: Record<string, any[]>,
    value: Record<string, any>,
    signature: string,
    expectedAddress: string
): Promise<boolean> {
    try {
        const recoveredAddress = ethers.verifyTypedData(domain, types, value, signature);
        return recoveredAddress.toLowerCase() === expectedAddress.toLowerCase();
    } catch (error) {
        console.error("❌ EIP712签名验证失败:", error);
        return false;
    }
};

