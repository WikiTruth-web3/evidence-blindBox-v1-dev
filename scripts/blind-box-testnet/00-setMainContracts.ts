import { ethers } from "hardhat";
import { user_oasis } from "../../account_admin";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import contractsAddress from "../../deployments/contracts-testnet.json"
import { CallFunctionParams } from "../types/call-params";
import { Main } from "../types/enums";


/**
npx hardhat run scripts/blind-box-testnet/00-setMainContracts.ts --network sapphire-testnet
 */

const MainList = [
    // {
    //     contract:Main.BlindBox,
    //     address:contractsAddress.Main.BlindBox
    // },
    // {
    //     contract:Main.Exchange,
    //     address:contractsAddress.Main.Exchange
    // },
    {
        contract:Main.FundManager,
        address:contractsAddress.Main.FundManager
    },
    // {
    //     contract:Main.SiweAuth,
    //     address:contractsAddress.Main.SiweAuth
    // },
    // {
    //     contract:Main.DaoTreasury,
    //     address:'0x67Ef70102D9Ac6d7Cc52830B0ac9349e0afb9E01' // Not contract
    // },
    // {
    //     contract:Main.Dao,
    //     address:'0x85d526809D03d17b0dBA17372Bae2E156958F260'
    // },
]

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

    // 1. 编排任务清单
    const tasks: CallFunctionParams[] = MainList.map(i => 
    (
        {
            taskName: "设置核心合约",
            contractsName: "AddressManager",
            functionName: "setMainContract",
            params: [i.contract,i.address],
            signer: adminSigner
        }
    )
    )

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
