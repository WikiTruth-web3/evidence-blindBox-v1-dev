import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { getSiweMsg, erc191sign } from "../utils/SiweAuth";

/**
 * SiweAuth 合约写入（撤销）批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/siweAuth_write.ts --network sapphire-testnet
 */

// 当前需要执行的任务列表
const current_executes = [
    'removeAuthToken',
];

async function main() {
    console.log("🚀 开始执行 SiweAuth 写入任务...");

    const network = await ethers.provider.getNetwork();
    const chainId = Number(network.chainId);
    if (chainId !== 23295) {
        console.error("当前网络ID不是23295，请检查网络配置");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("未找到有效的签名者 (adminSigner)");
        return;
    }

    // 1. 生成一个测试用 SIWE Token 用于撤销测试
    console.log("🎫 正在生成测试用 SIWE Token...");
    const domain = "wikitruth.xyz";
    const siweMsg = await getSiweMsg(domain, adminSigner, chainId);
    const signature = await erc191sign(siweMsg, adminSigner);
    const token = ethers.solidityPacked(["string", "bytes"], [siweMsg, signature.serialized]);

    // 2. 定义所有可能的写入任务
    const all_tasks: { [key: string]: CallFunctionParams } = {
        'removeAuthToken': {
            taskName: "撤销 SIWE 认证 Token",
            contractsName: "SiweAuth",
            functionName: "removeAuthToken",
            params: [token],
            signer: adminSigner // 必须有签名者进行交易
        }
    };

    // 3. 根据 current_executes 编排待执行任务
    const tasks_to_run: CallFunctionParams[] = current_executes
        .map(key => all_tasks[key])
        .filter(task => task !== undefined);

    if (tasks_to_run.length === 0) {
        console.log("⚠️ 没有匹配的任务需要执行，请检查 current_executes 数组");
        return;
    }

    // 4. 执行批量任务
    await ContractRunner.executeBatch(tasks_to_run, 5000);

    console.log("\n✅ SiweAuth 写入任务完成");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("执行过程出错:", error);
        process.exit(1);
    });
