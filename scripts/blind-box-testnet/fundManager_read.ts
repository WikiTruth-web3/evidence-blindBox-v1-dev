import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * FundManager 合约写入操作批处理脚本
 * 运行命令：npx hardhat run scripts/blind-box-testnet/fundManager_write.ts --network sapphire-testnet
 */

const executes = [
    "serviceFeeRate",
   
];

async function main() {
    console.log("🚀 开始执行 FundManager 写入任务...");

    const { adminSigner } = await getSigners_SapphireTestnet();
    const tokenAddr = ethers.ZeroAddress;
    const boxIds = [1, 2];

    const tasks: CallFunctionParams[] = [
        {
            taskName: "读取服务费率",
            contractsName: "FundManager",
            functionName: "serviceFeeRate",
            params: [],
            signer: adminSigner
        },
        {
            taskName: "读取辅助者费率",
            contractsName: "FundManager",
            functionName: "helperFeeRate",
            params: [],
            signer: adminSigner
        },
        {
            taskName: "读取订单金额",
            contractsName: "FundManager",
            functionName: "orderAmounts",
            params: [tokenAddr,tokenAddr],
            signer: adminSigner
        },
        {
            taskName: "读取奖励额度",
            contractsName: "FundManager",
            functionName: "rewardAmounts",
            params: [tokenAddr,tokenAddr],
            signer: adminSigner
        },
    ];
    const tasks_to_run: CallFunctionParams[] = Object.values(tasks).filter(t => executes.includes(t.functionName));

    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
