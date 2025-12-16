// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Signer, Contract, BigNumberish } from 'ethers';
import { HardhatRuntimeEnvironment } from "hardhat/types";

/**
 * 测试环境配置接口
 */
export interface TestConfig {
    chainId: number;
    networkName: string;
    isLocal: boolean;
    gasLimit?: number;
    gasPrice?: BigNumberish;
}

/**
 * 交易配置接口
 */
export interface TransactionConfig {
    gasLimit?: number;
    gasPrice?: BigNumberish;
    value?: BigNumberish;
    nonce?: number;
}

/**
 * 测试结果接口
 */
export interface TestResult {
    success: boolean;
    message: string;
    data?: any;
    error?: Error;
}

/**
 * 等待指定时间（毫秒）
 * 
 * @param ms 等待时间（毫秒）
 */
export const sleep = (ms: number): Promise<void> => {
    return new Promise(resolve => setTimeout(resolve, ms));
};

/**
 * 等待指定数量的区块
 * 
 * @param blockCount 要等待的区块数量
 */
export const waitForBlocks = async (blockCount: number): Promise<void> => {
    console.log(`⏳ 等待 ${blockCount} 个区块...`);
    
    const currentBlock = await ethers.provider.getBlockNumber();
    const targetBlock = currentBlock + blockCount;
    
    while (await ethers.provider.getBlockNumber() < targetBlock) {
        await sleep(1000); // 等待1秒后再次检查
    }
    
    console.log(`✅ 已等待 ${blockCount} 个区块`);
};

/**
 * 等待交易确认
 * 
 * @param txHash 交易哈希
 * @param confirmations 确认数量（默认1）
 * @returns 交易收据
 */
export const waitForTransaction = async (
    txHash: string, 
    confirmations: number = 1
): Promise<any> => {
    console.log(`⏳ 等待交易确认: ${txHash}`);
    
    try {
        const receipt = await ethers.provider.waitForTransaction(txHash, confirmations);
        console.log(`✅ 交易已确认，区块号: ${receipt?.blockNumber}`);
        return receipt;
    } catch (error) {
        console.error(`❌ 等待交易确认失败:`, error);
        throw error;
    }
};

/**
 * 获取账户余额
 * 
 * @param address 账户地址
 * @returns 余额（ETH）
 */
export const getBalance = async (address: string): Promise<string> => {
    try {
        const balance = await ethers.provider.getBalance(address);
        return ethers.formatEther(balance);
    } catch (error) {
        console.error(`❌ 获取账户 ${address} 余额失败:`, error);
        throw error;
    }
};

/**
 * 发送ETH
 * 
 * @param from 发送方签名者
 * @param to 接收方地址
 * @param amount 金额（ETH）
 * @param config 交易配置
 * @returns 交易哈希
 */
export const sendETH = async (
    from: Signer,
    to: string,
    amount: string,
    config?: TransactionConfig
): Promise<string> => {
    console.log(`💰 发送 ${amount} ETH 从 ${await from.getAddress()} 到 ${to}`);
    
    try {
        const tx = await from.sendTransaction({
            to,
            value: ethers.parseEther(amount),
            gasLimit: config?.gasLimit,
            gasPrice: config?.gasPrice,
            nonce: config?.nonce
        });
        
        console.log(`✅ 交易已发送，哈希: ${tx.hash}`);
        return tx.hash;
    } catch (error) {
        console.error("❌ 发送ETH失败:", error);
        throw error;
    }
};

/**
 * 部署合约
 * 
 * @param contractFactory 合约工厂实例
 * @param deployer 部署者签名者
 * @param args 构造函数参数
 * @param config 交易配置
 * @returns 部署的合约实例
 */
export const deployContract = async <T extends Contract>(
    contractFactory: any,
    deployer: Signer,
    args: any[] = [],
    config?: TransactionConfig
): Promise<T> => {
    console.log(`🚀 部署合约...`);
    
    try {
        // 验证参数
        if (!contractFactory || !deployer) {
            throw new Error("合约工厂和部署者不能为空");
        }
        
        // 检查合约工厂是否有 deploy 方法
        if (typeof contractFactory.deploy !== 'function') {
            throw new Error("提供的不是有效的合约工厂");
        }
        
        // 使用部署者连接合约工厂
        const connectedFactory = contractFactory.connect(deployer);
        
        // 部署合约
        const contract = await connectedFactory.deploy(...args, {
            gasLimit: config?.gasLimit,
            gasPrice: config?.gasPrice
        });
        
        // 等待部署完成
        await contract.waitForDeployment();
        const address = await contract.getAddress();
        
        console.log(`✅ 合约部署成功，地址: ${address}`);
        return contract as T;
    } catch (error) {
        console.error("❌ 合约部署失败:", error);
        throw error;
    }
};

/**
 * 调用合约方法并等待确认
 * 
 * @param contract 合约实例
 * @param methodName 方法名
 * @param args 方法参数
 * @param config 交易配置
 * @returns 交易收据
 */
export const callContractMethod = async (
    contract: Contract,
    methodName: string,
    args: any[] = [],
    config?: TransactionConfig
): Promise<any> => {
    console.log(`📞 调用合约方法: ${methodName}`);
    
    try {
        const tx = await contract[methodName](...args, {
            gasLimit: config?.gasLimit,
            gasPrice: config?.gasPrice,
            value: config?.value
        });
        
        const receipt = await tx.wait();
        console.log(`✅ 方法调用成功，交易哈希: ${tx.hash}`);
        return receipt;
    } catch (error) {
        console.error(`❌ 调用方法 ${methodName} 失败:`, error);
        throw error;
    }
};

/**
 * 读取合约状态
 * 
 * @param contract 合约实例
 * @param methodName 方法名
 * @param args 方法参数
 * @returns 返回值
 */
export const readContractState = async (
    contract: Contract,
    methodName: string,
    args: any[] = []
): Promise<any> => {
    try {
        const result = await contract[methodName](...args);
        console.log(`📖 读取状态 ${methodName}:`, result.toString());
        return result;
    } catch (error) {
        console.error(`❌ 读取状态 ${methodName} 失败:`, error);
        throw error;
    }
};

/**
 * 验证合约事件
 * 
 * @param receipt 交易收据
 * @param eventName 事件名
 * @param expectedArgs 期望的事件参数
 * @returns 验证结果
 */
export const verifyContractEvent = (
    receipt: any,
    eventName: string,
    contract: Contract,
    expectedArgs?: any[]
): TestResult => {
    try {
        const event = receipt.logs.find((log: any) => {
            try {
                const parsed = contract.interface.parseLog(log);
                return parsed?.name === eventName;
            } catch {
                return false;
            }
        });
        
        if (!event) {
            return {
                success: false,
                message: `未找到事件: ${eventName}`
            };
        }
        
        if (expectedArgs) {
            const parsed = contract.interface.parseLog(event);
            for (let i = 0; i < expectedArgs.length; i++) {
                if (parsed?.args[i] !== expectedArgs[i]) {
                    return {
                        success: false,
                        message: `事件参数不匹配，索引 ${i}: 期望 ${expectedArgs[i]}, 实际 ${parsed?.args[i]}`
                    };
                }
            }
        }
        
        return {
            success: true,
            message: `事件 ${eventName} 验证成功`,
            data: event
        };
    } catch (error) {
        return {
            success: false,
            message: `验证事件失败: ${error}`,
            error: error as Error
        };
    }
};

/**
 * 生成随机地址
 */
export const generateRandomAddress = (): string => {
    return ethers.Wallet.createRandom().address;
};

/**
 * 生成随机私钥
 */
export const generateRandomPrivateKey = (): string => {
    return ethers.Wallet.createRandom().privateKey;
};

/**
 * 格式化大数字
 * 
 * @param value 大数字
 * @param decimals 小数位数
 * @returns 格式化后的字符串
 */
export const formatBigNumber = (value: BigNumberish, decimals: number = 18): string => {
    return ethers.formatUnits(value, decimals);
};

/**
 * 解析大数字
 * 
 * @param value 字符串值
 * @param decimals 小数位数
 * @returns 大数字
 */
export const parseBigNumber = (value: string, decimals: number = 18): bigint => {
    return ethers.parseUnits(value, decimals);
};

/**
 * 检查地址是否为零地址
 */
export const isZeroAddress = (address: string): boolean => {
    return address === ethers.ZeroAddress;
};

/**
 * 检查地址是否有效
 */
export const isValidAddress = (address: string): boolean => {
    return ethers.isAddress(address);
};

/**
 * 获取当前时间戳
 */
export const getCurrentTimestamp = (): number => {
    return Math.floor(Date.now() / 1000);
};

/**
 * 时间戳转日期字符串
 */
export const timestampToDateString = (timestamp: number): string => {
    return new Date(timestamp * 1000).toISOString();
};

/**
 * 重试函数
 * 
 * @param fn 要重试的函数
 * @param maxRetries 最大重试次数
 * @param delay 重试间隔（毫秒）
 * @returns 函数执行结果
 */
export const retry = async <T>(
    fn: () => Promise<T>,
    maxRetries: number = 3,
    delay: number = 1000
): Promise<T> => {
    let lastError: Error;
    
    for (let i = 0; i <= maxRetries; i++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error as Error;
            
            if (i === maxRetries) {
                throw lastError;
            }
            
            console.log(`⚠️ 第 ${i + 1} 次尝试失败，${delay}ms 后重试...`);
            await sleep(delay);
        }
    }
    
    throw lastError!;
};

/**
 * 测试超时包装器
 * 
 * @param fn 要执行的函数
 * @param timeout 超时时间（毫秒）
 * @returns 函数执行结果
 */
export const withTimeout = async <T>(
    fn: () => Promise<T>,
    timeout: number = 30000
): Promise<T> => {
    return Promise.race([
        fn(),
        new Promise<never>((_, reject) => {
            setTimeout(() => reject(new Error(`操作超时 (${timeout}ms)`)), timeout);
        })
    ]);
};

/**
 * 创建测试报告
 */
export const createTestReport = (results: TestResult[]): string => {
    const total = results.length;
    const passed = results.filter(r => r.success).length;
    const failed = total - passed;
    
    let report = `\n📊 测试报告\n`;
    report += `总测试数: ${total}\n`;
    report += `通过: ${passed} ✅\n`;
    report += `失败: ${failed} ❌\n`;
    report += `成功率: ${((passed / total) * 100).toFixed(2)}%\n\n`;
    
    if (failed > 0) {
        report += `❌ 失败的测试:\n`;
        results.filter(r => !r.success).forEach((result, index) => {
            report += `${index + 1}. ${result.message}\n`;
            if (result.error) {
                report += `   错误: ${result.error.message}\n`;
            }
        });
    }
    
    return report;
};
