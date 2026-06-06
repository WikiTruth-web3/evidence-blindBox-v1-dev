import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import erc20 from "../../deployments/sapphire_testnet_erc20.json";

/**
npx hardhat run scripts/blind-box-testnet/mockPriceOracle-read.ts --network sapphire-testnet
 */

const executes = [
    // "setAdmin",
    'getPrice',
    // 'createAndPublish',
];

async function main() {
    console.log("🚀 开始执行 BlindBox 写入任务...");

    const { adminSigner } = await getSigners_SapphireTestnet();
    // const token1= "QmTest123...";
    // const token2 = "0x1234...";

    const tasks: CallFunctionParams[] = [
        {
            taskName: "设置admin",
            contractsName: "MockPriceOracle",
            functionName: "setAdmin",
            params: [''],
            signer: adminSigner
        },
        {
            taskName: "读取价格",
            contractsName: "MockPriceOracle",
            functionName: "getPrice",
            params: [erc20.EMC_Privacy, erc20.wROSE_Privacy],
            signer: adminSigner
        },
        {
            taskName: "读取admin",
            contractsName: "MockPriceOracle",
            functionName: "admin",
            params: [],
            signer: adminSigner
        },
    ];

    const tasks_to_run: CallFunctionParams[] = Object.values(tasks).filter(t => executes.includes(t.functionName));
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
