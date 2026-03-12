import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { TaskMap, IExchangeWrite } from "../types/contracts-functions";

/**
 * Exchange 合约写入操作批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/exchange_write.ts --network sapphire-testnet
 */

// 当前需要执行的任务列表（按顺序执行）
const current_executes: (keyof IExchangeWrite)[] = [
    'buy',
    // 'bid',
    'requestRefund',
];

async function main() {
    console.log("🚀 开始执行 Exchange 写入任务...");

    const network = await ethers.provider.getNetwork();
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络配置");
        return;
    }

    const { adminSigner, buyerSigner } = await getSigners_SapphireTestnet();
    const signer = adminSigner || buyerSigner; // 优先使用 admin，也可根据需要调整

    if (!signer) {
        console.error("未找到有效的签名者");
        return;
    }

    // 测试数据定义
    const testBoxId = BigInt(1); 
    const testToken = ethers.ZeroAddress; // 示例代币地址
    const testPrice = ethers.parseEther("0.1");


    // 定义所有可能的写入任务
    const all_tasks: TaskMap<IExchangeWrite> = {

        'setAddress': {
            taskName: "设置合约关联地址",
            contractsName: "Exchange",
            functionName: "setAddress",
            params: [],
            signer: adminSigner
        },
        'sell': {
            taskName: "上架销售",
            contractsName: "Exchange",
            functionName: "sell",
            params: [testBoxId, testToken, testPrice],
            signer: adminSigner
        },
        'auction': {
            taskName: "开启拍卖",
            contractsName: "Exchange",
            functionName: "auction",
            params: [testBoxId, testToken, testPrice],
            signer: adminSigner
        },
        'buy': {
            taskName: "购买 TruthBox",
            contractsName: "Exchange",
            functionName: "buy",
            params: [testBoxId],
            signer: buyerSigner // 通常买家操作
        },
        'bid': {
            taskName: "参与竞拍",
            contractsName: "Exchange",
            functionName: "bid",
            params: [testBoxId],
            signer: buyerSigner
        },
        'requestRefund': {
            taskName: "发起退款申请",
            contractsName: "Exchange",
            functionName: "requestRefund",
            params: [testBoxId],
            signer: buyerSigner
        },
        'cancelRefund': {
            taskName: "取消退款申请",
            contractsName: "Exchange",
            functionName: "cancelRefund",
            params: [testBoxId],
            signer: buyerSigner
        },
        'agreeRefund': {
            taskName: "同意退款",
            contractsName: "Exchange",
            functionName: "agreeRefund",
            params: [testBoxId],
            signer: adminSigner // 通常卖家/管理员操作
        },
        'refuseRefund': {
            taskName: "拒绝退款",
            contractsName: "Exchange",
            functionName: "refuseRefund",
            params: [testBoxId],
            signer: adminSigner
        },
        'completeOrder': {
            taskName: "确认完成订单",
            contractsName: "Exchange",
            functionName: "completeOrder",
            params: [testBoxId],
            signer: adminSigner
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

    // 执行批量任务
    await ContractRunner.executeBatch(tasks_to_run, 5000);

    console.log("\n✅ Exchange 写入任务批处理完成");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("执行过程出错:", error);
        process.exit(1);
    });