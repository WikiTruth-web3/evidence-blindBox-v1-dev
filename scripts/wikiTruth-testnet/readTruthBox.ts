import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
import { getSiweMsg, erc191sign  } from "../utils/SiweAuth";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";

/**
 * 
 * @returns 读取WikiTruth的TruthBox合约数据
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/readTruthBox.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始读取WikiTruth的TruthBox合约数据...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    const { minterSigner } = await getSigners_SapphireTestnet();
    if (!minterSigner) {
        console.error("minterSigner不存在");
        return;
    }

    const siweStr = await getSiweMsg("wikitruth.eth.limo", minterSigner, 23295);
    if (!siweStr) {
        console.error("siweStr不存在");
        return;
    }
    const siweSig = await erc191sign(siweStr, minterSigner);
    if (!siweSig) {
        console.error("siweSig不存在");
        return;
    }
    // console.log(" login SiweAuth...");
    // const siweAuth = await ethers.getContractAt("SiweAuthWikiTruth", wikiTruth_contracts_address.siweAuth);
    // const siweToken = await siweAuth.login(siweStr, siweSig);
    // console.log("login:", siweToken);
    // await new Promise(resolve => setTimeout(resolve, 5000));
    
    // console.log("\nlogin SiweAuth完成");

    // =========================================== View functions=============================================

    // getPrivateData(uint256 boxId_, bytes memory siweToken_)
    const truthBoxAddress = wikiTruth_contracts_address.truthBox;

    const truthBox = await ethers.getContractAt("TruthBox", truthBoxAddress);
    const truthBox_minter = truthBox.connect(minterSigner) as any;

    // const tx_truthBox = await truthBox_minter.getPrivateData(0, siweToken);
    // console.log("getPrivateData:", tx_truthBox);
    // await new Promise(resolve => setTimeout(resolve, 5000));

    const getBasicData = await truthBox_minter.getBasicData(15);
    console.log("getBasicData_0:", getBasicData);
    await new Promise(resolve => setTimeout(resolve, 5000));



}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
    