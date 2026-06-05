import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * Forwarder 合约读取操作脚本
 */

const executes = ['isTargetWhitelisted', 'getMaxGasLimit'];

async function main() {
    console.log("🔍 开始读取 Forwarder 合约状态...");
    const testTarget = ethers.ZeroAddress;

    const tasks: CallFunctionParams[] = [
        {
            taskName: "检查目标合约是否在白名单",
            contractsName: "Forwarder",
            functionName: "isTargetWhitelisted",
            params: [testTarget],
            signer: null
        },
        {
            taskName: "获取最大 Gas 限制",
            contractsName: "Forwarder",
            functionName: "getMaxGasLimit",
            params: [],
            signer: null
        }
    ];
    const tasks_to_run: CallFunctionParams[] = Object.values(tasks).filter(t => executes.includes(t.functionName));
    await ContractRunner.executeBatch(tasks_to_run, 1000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
