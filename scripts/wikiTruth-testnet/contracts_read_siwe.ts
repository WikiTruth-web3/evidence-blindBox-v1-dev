import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { getSiweMsg, erc191sign } from "../utils/SiweAuth";

/**
 * 跨合约 SIWE 认证读取批处理脚本
 * 将所有需要 SIWE Token 的读取函数集中于此，避免重复生成 Token
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/contracts_read_siwe.ts --network sapphire-testnet
 */

// 当前需要执行的查询列表
const current_executes = [
    'myUserId',
    'getSecretData',
    'calcPayMoney',
    'orderAmounts',
    'rewardAmounts'
];

async function main() {
    console.log("🔍 开始执行跨合约 SIWE 认证读取任务...");

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

    // 1. 生成一次 SIWE Token 供所有任务使用
    console.log("🎫 正在为跨合约读取生成 SIWE Token...");
    const domain = "wikitruth.io";
    const siweMsg = await getSiweMsg(domain, adminSigner, chainId);
    const signature = await erc191sign(siweMsg, adminSigner);
    const token = ethers.solidityPacked(["string", "bytes"], [siweMsg, signature.serialized]);

    // 测试数据
    const testBoxId = 1;
    const testTokenAddr = ethers.ZeroAddress;

    // 2. 定义所有跨合约 SIWE 相关的读取任务
    const all_tasks: { [key: string]: CallFunctionParams } = {
        'myUserId': {
            taskName: "UserManager: 获取当前用户 ID",
            contractsName: "UserManager",
            functionName: "myUserId",
            params: [token],
            signer: null
        },
        'getSecretData': {
            taskName: "TruthBox: 获取解密后的私密数据",
            contractsName: "TruthBox",
            functionName: "getSecretData",
            params: [testBoxId, token],
            signer: null
        },
        'calcPayMoney': {
            taskName: "Exchange: 计算待支付金额",
            contractsName: "Exchange",
            functionName: "calcPayMoney",
            params: [testBoxId, token],
            signer: null
        },
        'orderAmounts': {
            taskName: "FundManager: 获取订单金额",
            contractsName: "FundManager",
            functionName: "orderAmounts",
            params: [testBoxId, token],
            signer: null
        },
        'rewardAmounts': {
            taskName: "FundManager: 获取奖励余额",
            contractsName: "FundManager",
            functionName: "rewardAmounts",
            params: [testTokenAddr, token],
            signer: null
        }
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
