import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
const crypto = require('crypto');
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { boxList } from "../../private/boxList";
/**
 * 
 * @returns 创建WikiTruth的TruthBox合约数据
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/createTruthBox.ts --network sapphire-testnet
 */

/**
 * @notice 这个脚本不要轻易使用，因为它是测试中所使用的脚本。
 */

async function main() {
    console.log("开始创建WikiTruth的TruthBox合约数据...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    const { minterSigner } = await getSigners_SapphireTestnet();
    if (!minterSigner) {
        console.error("minterSigner不存在");
        return;
    }

    // =========================================== Write functions=============================================

    const truthBoxAddress = wikiTruth_contracts_address.truthBox;

    console.log("   1. 创建 TruthBox的私密数据...");
    const truthBox = await ethers.getContractAt("TruthBox", truthBoxAddress);
    const truthBox_minter = truthBox.connect(minterSigner) as any;

    for (const box of boxList) {
        if (box.mintMethod === "create") {
            const randomBytes = crypto.randomBytes(32);
            const priceUint256 = ethers.parseUnits(box.price.toString(), 18);
            // console.log("priceUint256:", priceUint256);

            const tx_truthBox = await truthBox_minter.create(
                box.to, 
                box.metadataNFTCID, 
                box.metadataBoxCID, 
                randomBytes, 
                priceUint256
            );
            await tx_truthBox.wait();
            console.log("create:", tx_truthBox.hash);
        } else if (box.mintMethod === "createAndPublish") {
            const tx_truthBox = await truthBox_minter.createAndPublish(
                box.to, 
                box.metadataNFTCID, 
                box.metadataBoxCID
            );
            await tx_truthBox.wait();
            console.log("createAndPublish:", tx_truthBox.hash);
        }
        await new Promise(resolve => setTimeout(resolve, 8000));
    }




}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
