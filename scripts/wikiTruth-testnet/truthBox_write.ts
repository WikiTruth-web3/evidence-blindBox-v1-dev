import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * TruthBox 合约写入操作批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/truthBox_write.ts --network sapphire-testnet
 */

const current_executes = [
    'create',
    // 'createAndPublish',
];

async function main() {
    console.log("🚀 开始执行 TruthBox 写入任务...");

    const { adminSigner, minterSigner } = await getSigners_SapphireTestnet();
    const testBoxId = 1;
    const testCID = "QmTest123...";
    const testKey = "0x1234...";
    const testPrice = ethers.parseEther("0.1");

    const all_tasks: { [key: string]: CallFunctionParams } = {
        'setAddress': {
            taskName: "设置关联地址",
            contractsName: "TruthBox",
            functionName: "setAddress",
            params: [],
            signer: adminSigner
        },
        'create': {
            taskName: "创建 TruthBox",
            contractsName: "TruthBox",
            functionName: "create",
            params: [testCID, testCID, testKey, testPrice],
            signer: minterSigner
        },
        'createAndPublish': {
            taskName: "创建并直接发布",
            contractsName: "TruthBox",
            functionName: "createAndPublish",
            params: [testCID, testCID],
            signer: minterSigner
        },
        'publishByMinter': {
            taskName: "由铸造者发布",
            contractsName: "TruthBox",
            functionName: "publishByMinter",
            params: [testBoxId],
            signer: minterSigner
        },
        'extendDeadline': {
            taskName: "延长截止日期",
            contractsName: "TruthBox",
            functionName: "extendDeadline",
            params: [testBoxId, 3600],
            signer: adminSigner
        },
        'delay': {
            taskName: "宽限延期 (Delay)",
            contractsName: "TruthBox",
            functionName: "delay",
            params: [testBoxId],
            signer: adminSigner
        },
        'addToBlacklist': {
            taskName: "加入黑名单",
            contractsName: "TruthBox",
            functionName: "addToBlacklist",
            params: [testBoxId],
            signer: adminSigner
        }
    };

    const tasks_to_run = current_executes.map(k => all_tasks[k]).filter(t => !!t);
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
