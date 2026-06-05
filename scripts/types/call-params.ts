import { BaseContract } from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import * as typechain from "../../typechain-types";

/**
 * 所有支持的合约映射表
 */
export interface AllContracts {
    AddressManager: typechain.AddressManager;
    BlindBox: typechain.BlindBox;
    Exchange: typechain.Exchange;
    FundManager: typechain.FundManager;
    Forwarder: typechain.Forwarder;
    SiweAuth: typechain.SiweAuth;
    UserManager: typechain.UserManager;
    MockPriceOracle: typechain.MockPriceOracle;
    IERC20: typechain.IERC20;
}

// 排除 BaseContract 的内置键，剩下的就是合约特有的键
type ContractExclusiveKeys<T> = Exclude<keyof T, keyof BaseContract>;

// 过滤出函数键
export type ContractFunctions<T> = {
    [K in ContractExclusiveKeys<T>]: T[K] extends (...args: any[]) => any ? K : never;
}[ContractExclusiveKeys<T>];

type FunctionKeys<T> = ContractFunctions<T>;

/**
 * 对每一个合约的每一个方法进行分布式联合，以实现 functionName 和 params 的强绑定约束
 */
type ContractTask<C extends keyof AllContracts, F extends FunctionKeys<AllContracts[C]> = FunctionKeys<AllContracts[C]>> = 
    F extends any ? {
        taskName?: string; // 任务描述，用于日志输出
        contractsName: C;
        contractAddress?: string; // 可选，用于覆盖默认合约地址
        functionName: F;
        params: AllContracts[C][F] extends (...args: any[]) => any ? Parameters<AllContracts[C][F]> : never;
        value?: bigint | string; // 可选，针对 payable 函数发送的原生代币金额
        signer: HardhatEthersSigner | null;
    } : never;

/**
 * 传递与智能合约交互的参数（联合类型）
 */
export type CallFunctionParams = {
    [C in keyof AllContracts]: ContractTask<C>
}[keyof AllContracts];

/**
 * 任务映射表约束，替代原有的 TaskMap 硬编码，直接根据合约名称从 typechain 提取对应函数并做强类型绑定
 */
export type TaskMap<C extends keyof AllContracts> = {
    [F in ContractFunctions<AllContracts[C]>]?: Extract<CallFunctionParams, { contractsName: C, functionName: F }>
};





