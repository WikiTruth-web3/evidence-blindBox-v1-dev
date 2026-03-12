import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * UserManager 合约读取操作脚本
 */

const current_executes = ['isBlacklisted'];

async function main() {
    console.log("🔍 开始读取 UserManager 合约状态...");
    const testUser = ethers.ZeroAddress;

    const all_tasks: { [key: string]: CallFunctionParams } = {
        'isBlacklisted': {
            taskName: "检查用户是否在黑名单",
            contractsName: "UserManager",
            functionName: "isBlacklisted",
            params: [testUser],
            signer: null
        }
    };

    const tasks_to_run = current_executes.map(k => all_tasks[k]).filter(t => !!t);
    await ContractRunner.executeBatch(tasks_to_run, 1000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
