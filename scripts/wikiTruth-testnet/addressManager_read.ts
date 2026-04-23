import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { TaskMap, IAddressManagerRead } from "../types/contracts-functions";

/**
 * AddressManager 合约读取（查询）批处理脚本
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/addressManager_read.ts --network sapphire-testnet
 */

// 当前需要执行的查询列表
const current_executes: (keyof IAddressManagerRead)[] = [
    // 'dao',
    // 'governance',
    'daoFundManager',
    // 'userManager',
    // 'siweAuth',
    // 'truthBox',
    // 'exchange',
    // 'fundManager',
    // 'forwarder',
    'swapContracts',
    'settlementToken',
];

async function main() {
    console.log("🔍 开始读取 AddressManager 合约状态...");

    const network = await ethers.provider.getNetwork();
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络配置");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();

    // 测试数据定义
    const testTokenAddress = "0x"; // 示例 SIWE Token
    const testIndex = 0;
    const testContractAddress = "0x"; // 示例合约地址

    // 定义所有可能的读取任务
    const all_tasks: TaskMap<IAddressManagerRead> = {

        'admin': {
            taskName: "获取管理员地址",
            contractsName: "AddressManager",
            functionName: "admin",
            params: [],
            signer: null
        },
        'dao': {
            taskName: "获取DAO地址",
            contractsName: "AddressManager",
            functionName: "dao",
            params: [],
            signer: null
        },
        'governance': {
            taskName: "获取治理地址",
            contractsName: "AddressManager",
            functionName: "governance",
            params: [],
            signer: null
        },
        'daoFundManager': {
            taskName: "获取DAO基金管理器地址",
            contractsName: "AddressManager",
            functionName: "daoFundManager",
            params: [],
            signer: null
        },
        'userManager': {
            taskName: "获取用户管理器地址",
            contractsName: "AddressManager",
            functionName: "userManager",
            params: [],
            signer: null
        },
        'siweAuth': {
            taskName: "获取SIWE认证地址",
            contractsName: "AddressManager",
            functionName: "siweAuth",
            params: [],
            signer: null
        },
        'truthBox': {
            taskName: "获取TruthBox地址",
            contractsName: "AddressManager",
            functionName: "truthBox",
            params: [],
            signer: null
        },
        'exchange': {
            taskName: "获取Exchange地址",
            contractsName: "AddressManager",
            functionName: "exchange",
            params: [],
            signer: null
        },
        'fundManager': {
            taskName: "获取FundManager地址",
            contractsName: "AddressManager",
            functionName: "fundManager",
            params: [],
            signer: null
        },
        'forwarder': {
            taskName: "获取Forwarder地址",
            contractsName: "AddressManager",
            functionName: "forwarder",
            params: [],
            signer: null
        },
        'swapContracts': {
            taskName: "获取SwapContracts地址",
            contractsName: "AddressManager",
            functionName: "swapContracts",
            params: [],
            signer: null
        },
        'settlementToken': {
            taskName: "获取结算代币地址",
            contractsName: "AddressManager",
            functionName: "settlementToken",
            params: [],
            signer: null
        },
        'isProjectContract': {
            taskName: "检查合约是否是项目合约",
            contractsName: "AddressManager",
            functionName: "isProjectContract",
            params: [testContractAddress],
            signer: null
        },
        'getTokenList': {
            taskName: "获取代币列表",
            contractsName: "AddressManager",
            functionName: "getTokenList",
            params: [],
            signer: null
        },
        'isTokenSupported': {
            taskName: "检查代币是否支持",
            contractsName: "AddressManager",
            functionName: "isTokenSupported",
            params: [testTokenAddress],
            signer: null
        },
        'reservedList': {
            taskName: "获取保留列表",
            contractsName: "AddressManager",
            functionName: "reservedList",
            params: [],
            signer: null
        },
        'getAddressFromIndex': {
            taskName: "获取地址从索引",
            contractsName: "AddressManager",
            functionName: "getAddressFromIndex",
            params: [testIndex],
            signer: null
        },
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

    console.log("\n✅ AddressManager 状态读取完成");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("执行过程出错:", error);
        process.exit(1);
    });