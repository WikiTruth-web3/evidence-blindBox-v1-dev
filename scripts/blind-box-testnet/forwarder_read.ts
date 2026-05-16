import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * Forwarder 合约读取操作脚本
 */

const current_executes = ['isTargetWhitelisted', 'getMaxGasLimit'];

async function main() {
    console.log("🔍 开始读取 Forwarder 合约状态...");
    const testTarget = ethers.ZeroAddress;

    const all_tasks: { [key: string]: CallFunctionParams } = {
        'isTargetWhitelisted': {
            taskName: "检查目标合约是否在白名单",
            contractsName: "Forwarder",
            functionName: "isTargetWhitelisted",
            params: [testTarget],
            signer: null
        },
        'getMaxGasLimit': {
            taskName: "获取最大 Gas 限制",
            contractsName: "Forwarder",
            functionName: "getMaxGasLimit",
            params: [],
            signer: null
        }
    };

    const tasks_to_run = current_executes.map(k => all_tasks[k]).filter(t => !!t);
    await ContractRunner.executeBatch(tasks_to_run, 1000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
