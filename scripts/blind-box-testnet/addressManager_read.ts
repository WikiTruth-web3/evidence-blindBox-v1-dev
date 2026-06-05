import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams, ContractFunctions } from "../types/call-params";
import { AddressManager } from "../../typechain-types";

/**
 * AddressManager 合约读取（查询）批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/addressManager_read.ts --network sapphire-testnet
 */

// 当前需要执行的查询列表
const executes = [
    'settlementToken',
];

async function main() {
    console.log("🔍 开始读取 AddressManager 合约状态...");

    const network = await ethers.provider.getNetwork();
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络配置");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("未找到有效的签名者 (adminSigner)");
        return;
    }

    // 测试数据定义
    const testTokenAddress = "0x"; // 示例 SIWE Token
    const testContractAddress = "0x"; // 示例合约地址

    // 定义所有可能的读取任务
    const tasks: CallFunctionParams[] = [

        {
            taskName: "获取管理员地址",
            contractsName: "AddressManager",
            functionName: "admin",
            params: [],
            signer: adminSigner
        },
        {
            taskName: "获取结算代币地址",
            contractsName: "AddressManager",
            functionName: "settlementToken",
            params: [],
            signer: adminSigner
        },
        {
            taskName: "检查合约是否是项目合约",
            contractsName: "AddressManager",
            functionName: "isProjectContract",
            params: [testContractAddress],
            signer: adminSigner
        },
 
        {
            taskName: "检查代币是否支持",
            contractsName: "AddressManager",
            functionName: "isTokenSupported",
            params: [testTokenAddress],
            signer: adminSigner
        },
    ];

    // 根据 current_executes 编排待执行任务
    const tasks_to_run: CallFunctionParams[] = Object.values(tasks).filter(t => executes.includes(t.functionName));

    // 执行批量查询
    // 读取操作通常不需要长延迟，设为 1000ms 即可
    await ContractRunner.executeBatch(tasks_to_run, 1000);

    console.log("\n✅ AddressManager 状态读取完成");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("执行过程出错:", error);
        process.exit(1);
    });