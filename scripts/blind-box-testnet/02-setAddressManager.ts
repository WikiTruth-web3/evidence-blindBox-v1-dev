import { ethers } from "hardhat";
import { user_oasis } from "../../account_admin";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import token_contracts_address from "../../deployments/sapphire_testnet_erc20.json";
import contractsAddress from "../../deployments/contracts-testnet.json"
import { CallFunctionParams } from "../types/call-params";

/**
 * npx hardhat run scripts/blind-box-testnet/02-setAddressManager.ts --network sapphire-testnet
 */

// 1. 利用条件类型动态筛选出 AllContracts 中所有支持 "setAddressManager" 方法的合约名称
import { AllContracts, ContractFunctions } from "../types/call-params";

type ContractsWithSetAddressManager = {
    [C in keyof AllContracts]: "setAddressManager" extends ContractFunctions<AllContracts[C]> ? C : never;
}[keyof AllContracts];

// 2. 编排任务清单 (强约束为只能是 setAddressManager 函数调用)
type SetAddressManagerTask = Extract<CallFunctionParams, { functionName: "setAddressManager" }>;


const executes: ContractsWithSetAddressManager[] = [
    'BlindBox',
    'Exchange',
    'FundManager',
    'Forwarder',
    'UserManager',
];

async function main() {
    console.log("🚀 开始执行 AddressManager 批量初始化流程...");

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) return;

    const adminAddress = user_oasis.admin.address;
    const daoTreasuryAddress = user_oasis.daoTreasury.address;

    if (!adminAddress || !daoTreasuryAddress) {
        console.error("adminAddress 或 daoTreasuryAddress 不存在");
        return;
    }


    const tasks: SetAddressManagerTask[] = executes.map(item => (
        {
            taskName: `设置合约 [${item}] 中的 AddressManager 地址`,
            contractsName: item,
            functionName: "setAddressManager",
            params: [contractsAddress.Main.AddressManager],
            signer: adminSigner
        } as SetAddressManagerTask
    ));

    // 2. 执行批量任务
    // 设置 8000ms 间隔以适应网络同步
    await ContractRunner.executeBatch(tasks, 8000);

    console.log("\n✅ AddressManager 批量初始化流程全部完毕");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("批量初始化失败:", error);
        process.exit(1);
    });
