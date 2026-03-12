import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { TaskMap, IExchangeRead } from "../types/contracts-functions";

/**
 * Exchange 合约读取（查询）批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/exchange_read.ts --network sapphire-testnet
 */

// 当前需要执行的查询列表
const current_executes: (keyof IExchangeRead)[] = [
    'acceptedToken',
    'refundPermit',
    'isInReviewDeadline'
];

async function main() {
    console.log("🔍 开始读取 Exchange 合约状态...");

    const network = await ethers.provider.getNetwork();
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络配置");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();

    // 测试数据定义
    const testBoxId = BigInt(1); 
    const dummySiweToken = "0x"; // 示例 SIWE Token

    // 定义所有可能的读取任务
    const all_tasks: TaskMap<IExchangeRead> = {

        'calcPayMoney': {
            taskName: "计算待支付金额",
            contractsName: "Exchange",
            functionName: "calcPayMoney",
            params: [testBoxId, dummySiweToken],
            signer: null
        },
        'acceptedToken': {
            taskName: "获取接受的代币地址",
            contractsName: "Exchange",
            functionName: "acceptedToken",
            params: [testBoxId],
            signer: null
        },
        'refundPermit': {
            taskName: "检查退款许可",
            contractsName: "Exchange",
            functionName: "refundPermit",
            params: [testBoxId],
            signer: null
        },
        'refundRequestDeadline': {
            taskName: "获取退款申请截止时间",
            contractsName: "Exchange",
            functionName: "refundRequestDeadline",
            params: [testBoxId],
            signer: null
        },
        'refundReviewDeadline': {
            taskName: "获取退款审核截止时间",
            contractsName: "Exchange",
            functionName: "refundReviewDeadline",
            params: [testBoxId],
            signer: null
        },
        'isInRequestRefundDeadline': {
            taskName: "检查是否在退款申请期内",
            contractsName: "Exchange",
            functionName: "isInRequestRefundDeadline",
            params: [testBoxId],
            signer: null
        },
        'isInReviewDeadline': {
            taskName: "检查是否在退款审核期内",
            contractsName: "Exchange",
            functionName: "isInReviewDeadline",
            params: [testBoxId],
            signer: null
        }
    };

    // 根据 current_executes 编排待执行任务
    const tasks_to_run: CallFunctionParams[] = current_executes
        .map(key => all_tasks[key])
        .filter(task => task !== undefined);

    if (tasks_to_run.length === 0) {
        console.log("⚠️ 没有匹配的任务需要执行，请检查 current_executes 数组");
        return;
    }

    // 执行批量查询
    // 读取操作通常不需要长延迟，设为 1000ms 即可
    await ContractRunner.executeBatch(tasks_to_run, 1000);

    console.log("\n✅ Exchange 状态读取完成");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("执行过程出错:", error);
        process.exit(1);
    });