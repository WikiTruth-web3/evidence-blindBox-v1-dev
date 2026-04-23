import { ethers } from "hardhat";
import { user_evm_WikiTruth } from "../../WikiTruth_account";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { core_contracts_address, token_contracts_address } from "../utils/contracts_address";
import { CallFunctionParams } from "../types/call-params";
import { v3_core_testnet_address, v3_periphery_testnet_address } from "../utils/v3_testnet_address";

/**
 * 示例：使用批量模式初始化 AddressManager
 * 我们可以将多个初始化步骤编排在一个数组中
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/01_initAddressManager_v2.ts --network sapphire-testnet
 */
async function main() {
    console.log("🚀 开始执行 AddressManager 批量初始化流程...");

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) return;

    const adminAddress = user_evm_WikiTruth.admin.address;
    const daoFundManagerAddress = user_evm_WikiTruth.daoFundManager.address;

    if (!adminAddress || !daoFundManagerAddress) {
        console.error("adminAddress 或 daoFundManagerAddress 不存在");
        return;
    }

    // 1. 编排任务清单
    const tasks: CallFunctionParams[] = [
        // {
        //     taskName: "设置地址列表",
        //     contractsName: "AddressManager",
        //     functionName: "setAddressList",
        //     params: [[
        //         adminAddress,           // dao 
        //         ethers.ZeroAddress,     // governance
        //         daoFundManagerAddress,  // daoFundManager 
        //         core_contracts_address.userManager,
        //         core_contracts_address.siweAuth,
        //         core_contracts_address.truthBox,
        //         core_contracts_address.exchange,
        //         core_contracts_address.fundManager,
        //         core_contracts_address.forwarder,
        //     ]],
        //     signer: adminSigner
        // },

        // {
        //     // address swapContract = swapContracts[0];
        //     // address quoter = swapContracts[1];
        //     taskName: "设置SwapContracts",
        //     contractsName: "AddressManager",
        //     functionName: "setSwapContracts",
        //     params: [[
        //         v3_periphery_testnet_address.swapRouter,
        //         v3_periphery_testnet_address.quoter
        //     ]],
        //     signer: adminSigner
        // },
        // {
        //     taskName: "设置结算代币",
        //     contractsName: "AddressManager",
        //     functionName: "setSettlementToken",
        //     params: [token_contracts_address.settlementToken],
        //     signer: adminSigner
        // },
        // {
        //     taskName: "添加支持代币 (wROSE.P)",
        //     contractsName: "AddressManager",
        //     functionName: "addToken",
        //     params: [token_contracts_address.wrosePrivacy],
        //     signer: adminSigner
        // },
        {
            taskName: "设置所有合约地址",
            contractsName: "AddressManager",
            functionName: "setAllAddress",
            params: [],
            signer: adminSigner
        }
    ];

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
