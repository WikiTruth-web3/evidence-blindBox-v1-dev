import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/blindBox_write.ts --network sapphire-testnet
 */

const executes = [
    'publishByMinter',
    'extendDeadline'
];
const boxId = 1;

async function main() {
    console.log("🚀 开始执行 BlindBox 写入任务...");

    const { adminSigner, minterSigner } = await getSigners_SapphireTestnet();

    const tasks:  CallFunctionParams[] = [
        {
            taskName: "设置关联地址",
            contractsName: "BlindBox",
            functionName: "setContracts",
            params: [],
            signer: adminSigner
        },
        {
            taskName: "由铸造者发布",
            contractsName: "BlindBox",
            functionName: "publishByMinter",
            params: [boxId],
            signer: minterSigner
        },
        {
            taskName: "延长截止日期",
            contractsName: "BlindBox",
            functionName: "extendDeadline",
            params: [boxId, 3600],
            signer: adminSigner
        },
        {
            taskName: "宽限延期 (Delay)",
            contractsName: "BlindBox",
            functionName: "delay",
            params: [boxId],
            signer: adminSigner
        },
        {
            taskName: "加入黑名单",
            contractsName: "BlindBox",
            functionName: "addToBlacklist",
            params: [boxId],
            signer: adminSigner
        }
    ];

    const tasks_to_run: CallFunctionParams[] = Object.values(tasks).filter(t => executes.includes(t.functionName));
    
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
