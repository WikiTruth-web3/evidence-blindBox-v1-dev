import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * FundManager 合约写入操作批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/fundManager_write.ts --network sapphire-testnet
 */

const current_executes = [
    'withdrawOrderAmounts',
    // 'withdrawRefundAmounts',
];

async function main() {
    console.log("🚀 开始执行 FundManager 写入任务...");

    const { adminSigner } = await getSigners_SapphireTestnet();
    const testTokenAddr = ethers.ZeroAddress;
    const testBoxIds = [1, 2];

    const all_tasks: { [key: string]: CallFunctionParams } = {
        'setAddress': {
            taskName: "设置关联地址",
            contractsName: "FundManager",
            functionName: "setAddress",
            params: [],
            signer: adminSigner
        },
        'withdrawOrderAmounts': {
            taskName: "提取订单金额",
            contractsName: "FundManager",
            functionName: "withdrawOrderAmounts",
            params: [testTokenAddr, testBoxIds],
            signer: adminSigner
        },
        'withdrawRefundAmounts': {
            taskName: "提取退款金额",
            contractsName: "FundManager",
            functionName: "withdrawRefundAmounts",
            params: [testTokenAddr, testBoxIds],
            signer: adminSigner
        },
        'withdrawRewards': {
            taskName: "提取奖励",
            contractsName: "FundManager",
            functionName: "withdrawRewards",
            params: [testTokenAddr],
            signer: adminSigner
        }
    };

    const tasks_to_run = current_executes.map(k => all_tasks[k]).filter(t => !!t);
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
