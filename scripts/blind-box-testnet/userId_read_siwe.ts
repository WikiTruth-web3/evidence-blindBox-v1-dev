import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { get_siwe_token } from "../utils/SiweAuth";
import { core_contracts_address } from "../utils/contracts_address";

/**
 * 运行命令：npx hardhat run scripts/blind-box-testnet/userId_read_siwe.ts --network sapphire-testnet
 */

const current_executes = [
    'myUserId',
];

async function main() {
    console.log("🔍 Read user id...");

    const network = await ethers.provider.getNetwork();
    const chainId = Number(network.chainId);
    if (chainId !== 23295) {
        console.error("The current chainId is not 23295, please check the chainId.");
        return;
    }

    const { daoFundManagerSigner } = await getSigners_SapphireTestnet();

    if (!daoFundManagerSigner) {
        console.error("The signers are not found, please check the .env file.");
        return;
    }



    // ---------------------------------------------------------------

    const domain = "wikitruth.xyz";
    const token = await get_siwe_token(domain, daoFundManagerSigner, chainId, core_contracts_address.siweAuth);

    

    // 2. -------------------------------------------------------------------
    const all_tasks: { [key: string]: CallFunctionParams } = {
        'myUserId': {
            taskName: "UserManager: 获取当前用户 ID",
            contractsName: "UserManager",
            functionName: "myUserId",
            params: [token],
            signer: null
        },
    };

    // 3. 编排并执行
    const tasks_to_run: CallFunctionParams[] = current_executes
        .map(key => all_tasks[key])
        .filter(task => task !== undefined);

    if (tasks_to_run.length === 0) {
        console.log("⚠️ 没有匹配的任务需要执行");
        return;
    }

    await ContractRunner.executeBatch(tasks_to_run, 1000);

    console.log("\n✅ 跨合约 SIWE 读取任务完成");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("执行出错:", error);
        process.exit(1);
    });
