import { ethers } from "hardhat";
import { user_oasis } from "../../account_admin";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { main_contracts_address, token_contracts_address } from "../utils/contracts_address";
import { CallFunctionParams } from "../types/call-params";
import { Main } from "../types/enums";
/**
 * 示例：使用批量模式初始化 AddressManager
 * 我们可以将多个初始化步骤编排在一个数组中
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/01_initAddressManager_v2.ts --network sapphire-testnet
 */

const SpreadList = [
    {
        contract:'Oracle',
        address:''
    },
]

async function main() {
    console.log("🚀 开始执行 AddressManager 批量初始化流程...");

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) return;

    const adminAddress = user_oasis.admin.address;

    if (!adminAddress ) {
        console.error("adminAddress不存在");
        return;
    }

    // 1. 编排任务清单
    const tasks: CallFunctionParams[] = SpreadList.map(i => (
        {
            taskName: "设置扩展合约",
            contractsName: "AddressManager",
            functionName: "setSpreadContract",
            params: [i.contract,i.address],
            signer: adminSigner
        }
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
