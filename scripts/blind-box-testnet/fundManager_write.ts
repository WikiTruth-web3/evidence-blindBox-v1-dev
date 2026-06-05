import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * FundManager 合约写入操作批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/fundManager_write.ts --network sapphire-testnet
 */

const executes = [
    'withdrawOrderAmounts',
    // 'withdrawRefundAmounts',
];

async function main() {
    console.log("🚀 开始执行 FundManager 写入任务...");

    const { adminSigner } = await getSigners_SapphireTestnet();
    const tokenAddr = ethers.ZeroAddress;
    const boxIds = [1, 2];

    const tasks: CallFunctionParams[] = [
        {
            taskName: "设置关联地址",
            contractsName: "FundManager",
            functionName: "setContracts",
            params: [],
            signer: adminSigner
        },
        {
            taskName: "提取订单金额",
            contractsName: "FundManager",
            functionName: "withdrawOrderAmounts",
            params: [tokenAddr, boxIds, tokenAddr],
            signer: adminSigner
        },
        {
            taskName: "提取退款金额",
            contractsName: "FundManager",
            functionName: "withdrawRefundAmounts",
            params: [tokenAddr, boxIds,tokenAddr],
            signer: adminSigner
        },
        {
            taskName: "提取奖励",
            contractsName: "FundManager",
            functionName: "withdrawRewards",
            params: [tokenAddr,tokenAddr],
            signer: adminSigner
        }
    ];
    const tasks_to_run: CallFunctionParams[] = Object.values(tasks).filter(t => executes.includes(t.functionName));

    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
