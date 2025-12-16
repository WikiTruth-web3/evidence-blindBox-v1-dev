import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
import { v3_core_testnet_address, v3_periphery_testnet_address } from "../utils/v3_testnet_address";
// import { domainList } from "../../test/utils";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";

/**
 * 
 * @returns 设置WikiTruth的合约的基本数据至sapphire-testnet测试网
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/02_setBaseData.ts --network sapphire-testnet
 */



async function main() {
    console.log("开始设置WikiTruth的合约的基本数据...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("adminSigner不存在");
        return;
    }


    // 3. 分别用 admin 身份调用各个合约的 setBaseData
    console.log("\n3. 设置各个合约的基本数据...");
    
    console.log("   3.1 设置 Exchange...");
    const exchange = await ethers.getContractAt("Exchange", wikiTruth_contracts_address.exchange);
    const exchange_admin = exchange.connect(adminSigner) as any;
    const tx_exchange = await exchange_admin.setRefundRequestPeriod(7 * 24 * 60 * 60);
    await tx_exchange.wait();
    const tx_exchange2 = await exchange_admin.setRefundReviewPeriod(15 * 24 * 60 * 60);
    await tx_exchange2.wait();
    await new Promise(resolve => setTimeout(resolve, 5000));
    const tx_exchange3 = await exchange_admin.setBidIncrementRate(110);
    await tx_exchange3.wait();
    console.log("   3.1.1 设置 Exchange完成");
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    console.log("   3.2 设置 FundManager...");
    const fundManager = await ethers.getContractAt("FundManager", wikiTruth_contracts_address.fundManager);
    const fundManager_admin = fundManager.connect(adminSigner) as any;
    const tx_fundManager = await fundManager_admin.setServiceFeeRate(30);
    await tx_fundManager.wait();
    const tx_fundManager2 = await fundManager_admin.setHelperRewardRate(10);
    await tx_fundManager2.wait();
    await new Promise(resolve => setTimeout(resolve, 5000));
    const tx_fundManager3 = await fundManager_admin.setExtraFeeRate(10);
    await tx_fundManager3.wait();
    const tx_fundManager4 = await fundManager_admin.setSlippageProtection(10);
    await tx_fundManager4.wait();
    console.log("   3.2.1 设置 FundManager完成");
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    console.log("   3.3 设置 TruthBox...");
    const truthBox = await ethers.getContractAt("TruthBox", wikiTruth_contracts_address.truthBox);
    const truthBox_admin = truthBox.connect(adminSigner) as any;
    const tx_truthBox = await truthBox_admin.setIncrementRate(200);
    await tx_truthBox.wait();
    console.log("   3.3.1 设置 TruthBox完成");
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    console.log("   3.4 设置 TruthNFT...");
    const truthNFT = await ethers.getContractAt("TruthNFT", wikiTruth_contracts_address.truthNFT);
    const truthNFT_admin = truthNFT.connect(adminSigner) as any;
    const tx5 = await truthNFT_admin.setNetwork("ipfs://", "");
    await tx5.wait();
    console.log("   3.4.1 设置 TruthNFT完成");
    await new Promise(resolve => setTimeout(resolve, 5000));


    
    // console.log("   3.6 设置 UserId...");
    // const userId = await ethers.getContractAt("UserId", wikiTruth_contracts_address.userId);
    // const userId_admin = userId.connect(adminSigner) as any;
    // const tx7 = await userId.;
    // await tx7.wait();

    // console.log("   3.5 设置 SiweAuth...");
    // const siweAuth = await ethers.getContractAt("SiweAuthWikiTruth", wikiTruth_contracts_address.siweAuth);
    // const siweAuth_admin = siweAuth.connect(adminSigner) as any;
    // const tx_siweAuth = await siweAuth_admin.
    // await tx_siweAuth.wait();
    // await new Promise(resolve => setTimeout(resolve, 5000));
    
    console.log("\n所有合约地址设置完成");


    // =========================================== View functions=============================================

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
    