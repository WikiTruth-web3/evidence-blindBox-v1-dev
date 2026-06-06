import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { get_siwe_token} from "../utils/SiweAuth";
import contractsAddress from "../../deployments/contracts-testnet.json"

/**
 * BlindBox 合约读取操作批处理脚本
 * 运行命令：npx hardhat run scripts/blind-box-testnet/blindBox_read-secret.ts --network sapphire-testnet
 */

const boxes = [
    '3',
    // '0',  '2', 
    // '4', '5', '6', '7', '8', 
    // '10', '11', '12', 
];

async function main() {
    console.log("🔍 开始批量读取 BlindBox 合约私密数据...");

    const network = await ethers.provider.getNetwork();
    
    const { buyerSigner:userSigner } = await getSigners_SapphireTestnet();

    if (!userSigner) {
        console.error("❌ 未获取到userSigner");
        return;
    }

    const tasks_to_run: CallFunctionParams[] = boxes.map(boxId => ({
        taskName: `获取 Box #${boxId} 的解密数据`,
        contractsName: "BlindBox",
        functionName: "getBasicData",
        params: [boxId],
        signer: null
    }));

    await ContractRunner.executeBatch(tasks_to_run, 5000);
    
    console.log("\n✅ 所有私密数据读取任务完成");
}

main().then(() => process.exit(0)).catch(e => { 
    console.error("❌ 执行过程中出错:");
    console.error(e); 
    process.exit(1); 
});
