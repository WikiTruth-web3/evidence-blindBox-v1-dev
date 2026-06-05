import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";

/**
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/blindBox_write.ts --network sapphire-testnet
 */

const executes = [
    // "setAdmin",
    'setPrice',
    "setAddressManager",
    // 'getPrice',
    // 'createAndPublish',
];

async function main() {
    console.log("🚀 开始执行 BlindBox 写入任务...");

    const { minterSigner } = await getSigners_SapphireTestnet();
    const boxCID = "QmTest123...";
    const key = "0x1234...";
    const price = ethers.parseEther("0.1");

    const tasks: CallFunctionParams[] = [
        {
            taskName: "设置admin",
            contractsName: "MockPriceOracle",
            functionName: "setAdmin",
            params: [''],
            signer: minterSigner
        },
        {
            taskName: "设置addressManager",
            contractsName: "MockPriceOracle",
            functionName: "setAddressManager",
            params: [''],
            signer: minterSigner
        },

        {
            taskName: "设置价格",
            contractsName: "MockPriceOracle",
            functionName: "setPrice",
            params: [boxCID, key, price],
            signer: minterSigner
        },
        {
            taskName: "读取价格",
            contractsName: "MockPriceOracle",
            functionName: "getPrice",
            params: [boxCID, key],
            signer: minterSigner
        },
        {
            taskName: "读取admin",
            contractsName: "MockPriceOracle",
            functionName: "admin",
            params: [],
            signer: minterSigner
        },
    ];

    const tasks_to_run: CallFunctionParams[] = Object.values(tasks).filter(t => executes.includes(t.functionName));
    await ContractRunner.executeBatch(tasks_to_run, 8000);
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
