import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Signer, Wallet } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { user_evm_WikiTruth } from "../WikiTruth_account";

/**
 * 网络配置接口
 */
interface NetworkConfig {
    chainId: number;
    name: string;
    isLocal: boolean;
}

/**
 * 测试账户接口
 */
export interface TestAccounts {
    admin: Wallet;
    minter: Wallet;
    buyer: Wallet;
    buyer2: Wallet;
    seller: Wallet;
    completer: Wallet;
}

/**
 * 支持的测试网络配置
 */
const SUPPORTED_NETWORKS: NetworkConfig[] = [
    { chainId: 23293, name: "sapphire_localnet", isLocal: true },
    { chainId: 23294, name: "sapphire_testnet", isLocal: false },
    { chainId: 23295, name: "sapphire_mainnet", isLocal: false },
    { chainId: 31337, name: "hardhat_local", isLocal: true },
    { chainId: 1337, name: "ganache_local", isLocal: true }
];

/**
 * 获取网络配置
 */
const getNetworkConfig = (chainId: number): NetworkConfig => {
    const config = SUPPORTED_NETWORKS.find(net => net.chainId === chainId);
    if (!config) {
        throw new Error(`不支持的链ID: ${chainId}。支持的链ID: ${SUPPORTED_NETWORKS.map(n => n.chainId).join(', ')}`);
    }
    return config;
};

/**
 * 验证私钥格式
 */
const validatePrivateKey = (privateKey: string, accountName: string): void => {
    if (!privateKey) {
        throw new Error(`${accountName} 的私钥未配置`);
    }
    
    if (!privateKey.startsWith('0x') || privateKey.length !== 66) {
        throw new Error(`${accountName} 的私钥格式无效，应为66位十六进制字符串（包含0x前缀）`);
    }
};

/**
 * 从配置创建钱包实例
 */
const createWalletFromConfig = (accountConfig: any, accountName: string): Wallet => {
    validatePrivateKey(accountConfig.privateKey, accountName);
    
    try {
        return new ethers.Wallet(accountConfig.privateKey, ethers.provider);
    } catch (error) {
        throw new Error(`创建 ${accountName} 钱包失败: ${error}`);
    }
};

/**
 * 获取测试账户
 * 根据测试网络ID，获取对应的测试账户
 * 
 * @param chainId 链ID
 * @returns 测试账户对象
 */
export const getAccount = async function (chainId: number| bigint): Promise<TestAccounts> {
    console.log(`🔍 获取链ID ${chainId} 的测试账户...`);
    
    if (typeof chainId === 'bigint') {
        chainId = Number(chainId);
    }

    try {
        const networkConfig = getNetworkConfig(chainId);
        console.log(`📡 网络: ${networkConfig.name} (${networkConfig.isLocal ? '本地' : '远程'})`);

        let accounts: TestAccounts;

        if (networkConfig.isLocal) {
            // 本地网络：从hardhat获取账户
            console.log("🏠 使用本地网络账户...");
            const signers = await ethers.getSigners();
            
            if (signers.length < 6) {
                throw new Error(`本地网络账户数量不足，需要至少6个账户，实际只有${signers.length}个`);
            }

            accounts = {
                admin: signers[0] as unknown as Wallet,
                minter: signers[1] as unknown as Wallet,
                buyer: signers[2] as unknown as Wallet,
                buyer2: signers[3] as unknown as Wallet,
                seller: signers[4] as unknown as Wallet,
                completer: signers[5] as unknown as Wallet
            };

        } else {
            // 远程网络：从配置文件获取账户
            console.log("🌐 使用远程网络账户...");
            
            // 验证配置文件
            if (!user_evm_WikiTruth) {
                throw new Error("远程网络账户配置未找到");
            }

            accounts = {
                admin: createWalletFromConfig(user_evm_WikiTruth.admin, "admin"),
                minter: createWalletFromConfig(user_evm_WikiTruth.minter, "minter"),
                buyer: createWalletFromConfig(user_evm_WikiTruth.buyer, "buyer"),
                buyer2: createWalletFromConfig(user_evm_WikiTruth.buyer2, "buyer2"),
                seller: createWalletFromConfig(user_evm_WikiTruth.seller, "seller"),
                completer: createWalletFromConfig(user_evm_WikiTruth.completer, "completer")
            };
        }

        // 验证所有账户地址
        console.log("✅ 账户地址验证:");
        for (const [role, wallet] of Object.entries(accounts)) {
            const address = await wallet.getAddress();
            console.log(`  ${role}: ${address}`);
        }

        console.log("🎉 成功获取所有测试账户");
        return accounts;

    } catch (error) {
        console.error("❌ 获取测试账户失败:", error);
        throw error;
    }
};

/**
 * 获取单个测试账户
 * 
 * @param chainId 链ID
 * @param role 账户角色
 * @returns 指定角色的钱包实例
 */
export const getAccountByRole = async function (
    chainId: number, 
    role: keyof TestAccounts
): Promise<Wallet> {
    const accounts = await getAccount(chainId);
    return accounts[role];
};

/**
 * 获取所有支持的链ID
 */
export const getSupportedChainIds = (): number[] => {
    return SUPPORTED_NETWORKS.map(net => net.chainId);
};

/**
 * 检查链ID是否支持
 */
export const isChainIdSupported = (chainId: number): boolean => {
    return SUPPORTED_NETWORKS.some(net => net.chainId === chainId);
};
