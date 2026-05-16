import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * BlindBox 合约读取操作批处理脚本
 * 运行命令：npx hardhat run scripts/blind-box-testnet/blindBox_read.ts --network sapphire-testnet
 */

const current_executes = [
    'getStatus',
    'getPrice',
    'getDeadline',
    'getBasicData',
    'isInBlacklist'
];

async function main() {
    console.log("🔍 开始读取 BlindBox 合约状态...");
    const { adminSigner } = await getSigners_SapphireTestnet();
    const testBoxId = 1;

    const all_tasks: { [key: string]: CallFunctionParams } = {
        'getStatus': {
            taskName: "获取状态",
            contractsName: "BlindBox",
            functionName: "getStatus",
            params: [testBoxId],
            signer: null
        },
        'getPrice': {
            taskName: "获取价格",
            contractsName: "BlindBox",
            functionName: "getPrice",
            params: [testBoxId],
            signer: null
        },
        'getDeadline': {
            taskName: "获取截止日期",
            contractsName: "BlindBox",
            functionName: "getDeadline",
            params: [testBoxId],
            signer: null
        },
        'getBasicData': {
            taskName: "获取基础数据 (Status, Price, Deadline)",
            contractsName: "BlindBox",
            functionName: "getBasicData",
            params: [testBoxId],
            signer: null
        },
        'isInBlacklist': {
            taskName: "检查是否在黑名单中",
            contractsName: "BlindBox",
            functionName: "isInBlacklist",
            params: [testBoxId],
            signer: null
        }
    };

    const tasks_to_run = current_executes.map(k => all_tasks[k]).filter(t => !!t);
    await ContractRunner.executeBatch(tasks_to_run, 1000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
