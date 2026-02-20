import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
const crypto = require('crypto');
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
/**
 * 
 * @returns 创建WikiTruth的TruthBox合约数据
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/truthBox_delay.ts --network sapphire-testnet
 */

const boxIdList = [
    '15'
]

async function main() {

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    const { buyerSigner } = await getSigners_SapphireTestnet();
    if (!buyerSigner) {
        console.error("signer不存在");
        return;
    }

    // =========================================== Write functions=============================================

    const truthBoxAddress = wikiTruth_contracts_address.truthBox;

    console.log("   1. delay TruthBox的deadline...");
    const truthBox = await ethers.getContractAt("TruthBox", truthBoxAddress);
    const truthBox_signer = truthBox.connect(buyerSigner) as any;

    for (const boxId of boxIdList) {
            const tx_truthBox = await truthBox_signer.delay(
                boxId
            );
            await tx_truthBox.wait();
            console.log("delay:", tx_truthBox.hash);
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
