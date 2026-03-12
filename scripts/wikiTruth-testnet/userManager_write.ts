import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * UserManager 合约写入操作脚本
 */

const current_executes = ['addBlacklist'];

async function main() {
    console.log("🚀 开始执行 UserManager 写入任务...");
    const { adminSigner } = await getSigners_SapphireTestnet();
    const testUser = ethers.ZeroAddress;

    const all_tasks: { [key: string]: CallFunctionParams } = {
        'setAddress': {
            taskName: "设置关联地址",
            contractsName: "UserManager",
            functionName: "setAddress",
            params: [],
            signer: adminSigner
        },
        'addBlacklist': {
            taskName: "添加用户到黑名单",
            contractsName: "UserManager",
            functionName: "addBlacklist",
            params: [testUser],
            signer: adminSigner
        },
        'removeBlacklist': {
            taskName: "从黑名单移除用户",
            contractsName: "UserManager",
            functionName: "removeBlacklist",
            params: [testUser],
            signer: adminSigner
        }
    };

    const tasks_to_run = current_executes.map(k => all_tasks[k]).filter(t => !!t);
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
