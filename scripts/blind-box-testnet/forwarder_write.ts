import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * Forwarder 合约写入操作脚本
 */

const current_executes = ['setMaxGasLimit'];

async function main() {
    console.log("🚀 开始执行 Forwarder 写入任务...");
    const { adminSigner } = await getSigners_SapphireTestnet();
    const testTarget = ethers.ZeroAddress;

    const all_tasks: { [key: string]: CallFunctionParams } = {
        'setAddress': {
            taskName: "设置关联地址",
            contractsName: "Forwarder",
            functionName: "setAddress",
            params: [],
            signer: adminSigner
        },
        'setTargetStatus': {
            taskName: "设置目标合约白名单状态",
            contractsName: "Forwarder",
            functionName: "setTargetStatus",
            params: [testTarget, true],
            signer: adminSigner
        },
        'setMaxGasLimit': {
            taskName: "设置最大 Gas 限制",
            contractsName: "Forwarder",
            functionName: "setMaxGasLimit",
            params: [5000000],
            signer: adminSigner
        }
    };

    const tasks_to_run = current_executes.map(k => all_tasks[k]).filter(t => !!t);
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
