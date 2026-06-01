import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/blindBox_write.ts --network sapphire-testnet
 */

const current_executes = [
    'create',
    // 'createAndPublish',
];

async function main() {
    console.log("🚀 开始执行 BlindBox 写入任务...");

    const { minterSigner } = await getSigners_SapphireTestnet();
    const testCID = "QmTest123...";
    const testKey = "0x1234...";
    const testPrice = ethers.parseEther("0.1");

    const all_tasks: { [key: string]: CallFunctionParams } = {

        'create': {
            taskName: "创建 BlindBox",
            contractsName: "BlindBox",
            functionName: "create",
            params: [testCID, testCID, testKey, testPrice],
            signer: minterSigner
        },
        'createAndPublish': {
            taskName: "创建并直接发布",
            contractsName: "BlindBox",
            functionName: "createAndPublish",
            params: [testCID, testCID],
            signer: minterSigner
        },
    };

    const tasks_to_run = current_executes.map(k => all_tasks[k]).filter(t => !!t);
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
