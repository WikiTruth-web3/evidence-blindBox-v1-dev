import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import erc20 from "../../deployments/sapphire_testnet_erc20.json";

/**
npx hardhat run scripts/blind-box-testnet/00_setPriceOracle.ts --network sapphire-testnet
 */

const executes = [
    {
        token1: erc20.EMC_Privacy,
        token2: erc20.wROSE_Privacy,
        price: ethers.parseUnits("2", 18), // token1 = 2 * token2
    }
];

async function main() {
    console.log("🚀 开始执行 MockPriceOracle 设置价格任务...");

    // 💡 修复：setPrice 在 MockPriceOracle 中拥有 onlyAdmin 修饰符
    // 必须使用拥有 Admin 权限的 adminSigner，而不是 minterSigner 发起调用
    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("❌ 未找到有效的 admin 签名者，请检查网络配置或私钥");
        return;
    }

    const tasks: CallFunctionParams[] = executes.map(t => (
        {
            taskName: `设置价格: ${t.token1} <=> ${t.token2} 为 2.0`,
            contractsName: "MockPriceOracle",
            functionName: "setPrice",
            params: [t.token1, t.token2, t.price],
            signer: adminSigner
        } as CallFunctionParams
    ));

    const tasks_to_run: CallFunctionParams[] = Object.values(tasks);
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main()
    .then(() => process.exit(0))
    .catch(e => {
        console.error("❌ 任务执行失败:", e);
        process.exit(1);
    });
