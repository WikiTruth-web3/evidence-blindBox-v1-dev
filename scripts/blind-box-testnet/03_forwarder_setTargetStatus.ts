import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import main_contracts_address from "../../deployments/main_contracts_testnet.json"

/**
 * Forwarder 合约写入操作脚本
 */

const mainAddressList = [
    {
        address:main_contracts_address.BlindBox,
        status: true
    },
    {
        address:main_contracts_address.Exchange,
        status: true
    },
    {
        address:main_contracts_address.FundManager,
        status: true
    },
]

async function main() {
    console.log("🚀 开始执行 Forwarder 写入任务...");
    const { adminSigner } = await getSigners_SapphireTestnet();

    const tasks:CallFunctionParams[] = mainAddressList.map(t=>(
        {
            taskName: "设置目标合约白名单状态",
            contractsName: "Forwarder",
            functionName: "setTargetStatus",
            params: [t.address, t.status],
            signer: adminSigner
        }
    ))

    const tasks_to_run: CallFunctionParams[] = Object.values(tasks);

    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
