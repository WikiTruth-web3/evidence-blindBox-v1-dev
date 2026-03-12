import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { TaskMap, ISiweAuthRead } from "../types/contracts-functions";
import { getSiweMsg, erc191sign } from "../utils/SiweAuth";

/**
 * SiweAuth 合约读取（查询）批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/siweAuth_read.ts --network sapphire-testnet
 */

// 当前需要执行的查询列表
const current_executes: (keyof ISiweAuthRead)[] = [
    'getMsgSender',
    'getStatement',
    'getResources',
    'testStatementVerification',
    'testHasResourceAccess'
];


async function main() {
    console.log("🔍 开始读取 SiweAuth 合约状态...");

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

    // 1. 生成有效的 SIWE Token 用于测试
    console.log("🎫 正在生成测试用 SIWE Token...");
    const domain = "wikitruth.xyz";
    const statement = "Sign in to WikiTruth for authentication test.";
    const resources = ["https://wikitruth.xyz/api/v1"];
    
    const siweMsg = await getSiweMsg(domain, adminSigner, chainId, undefined, statement, resources);
    const signature = await erc191sign(siweMsg, adminSigner);
    
    // 将消息和签名打包成 Token (此处格式需与合约 ISiweAuth 接收格式一致)
    // 假设合约中是用这种方式拼接的
    const token = ethers.solidityPacked(["string", "bytes"], [siweMsg, signature.serialized]);

    // 2. 定义所有可能的读取任务
    const all_tasks: TaskMap<ISiweAuthRead> = {

        'getMsgSender': {
            taskName: "获取 Token 对应的消息发送者",
            contractsName: "SiweAuth",
            functionName: "getMsgSender",
            params: [token],
            signer: null
        },
        'getStatement': {
            taskName: "获取 Token 中的 Statement",
            contractsName: "SiweAuth",
            functionName: "getStatement",
            params: [token],
            signer: null
        },
        'getResources': {
            taskName: "获取 Token 中的 Resources 列表",
            contractsName: "SiweAuth",
            functionName: "getResources",
            params: [token],
            signer: null
        },
        'testStatementVerification': {
            taskName: "验证 Statement 是否匹配",
            contractsName: "SiweAuth",
            functionName: "testStatementVerification",
            params: [token, statement],
            signer: null
        },
        'testHasResourceAccess': {
            taskName: "验证资源访问权限",
            contractsName: "SiweAuth",
            functionName: "testHasResourceAccess",
            params: [token, resources[0]],
            signer: null
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

    // 4. 执行批量查询
    await ContractRunner.executeBatch(tasks_to_run, 1000);

    console.log("\n✅ SiweAuth 状态读取完成");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("执行过程出错:", error);
        process.exit(1);
    });
