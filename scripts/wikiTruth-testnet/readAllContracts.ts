import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
import { v3_core_testnet_address, v3_periphery_testnet_address } from "../utils/v3_testnet_address";
// import { domainList } from "../../test/utils";

/**
 * 
 * @returns 读取WikiTruth的合约数据
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/readAllContracts.ts --network sapphire-testnet
 */

const contracts = [
    // "AddressManager",
    // "Exchange",
    // "FundManager",
    // "TruthBox",
    // "TruthNFT",
    "SiweAuth",
    // "UserId",
    // "none"
]

async function main() {
    console.log("开始读取WikiTruth的所有合约数据...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    if (contracts.includes('none')) {
        console.error("No contracts to read");
        return;
    }

    if (contracts.includes('AddressManager')) {
        console.log("   3.1 读取 AddressManager...");
        const addressManager = await ethers.getContractAt("AddressManager", wikiTruth_contracts_address.addressManager);
        // const tx_addressManager = await addressManager.getTokenList();
        // console.log("addressManager_tokenList :", tx_addressManager);
        const tx_addressManager = await addressManager.implementation();
        console.log("implementation():", tx_addressManager);
        await new Promise(resolve => setTimeout(resolve, 5000));
    }

    if (contracts.includes('Exchange')) {

        console.log("   3.1 读取 Exchange...");
        const exchange = await ethers.getContractAt("Exchange", wikiTruth_contracts_address.exchange);
        const tx_exchange = await exchange.implementation();
        console.log("implementation():", tx_exchange);
        // const tx_exchange2 = await exchange.refundReviewPeriod();
        // console.log("refundReviewPeriod:", tx_exchange2);
        // const tx_exchange3 = await exchange.bidIncrementRate();
        // console.log("bidIncrementRate:", tx_exchange3);
        await new Promise(resolve => setTimeout(resolve, 5000));
    }

    if (contracts.includes('FundManager')) {
        console.log("   3.2 读取 FundManager...");
        const fundManager = await ethers.getContractAt("FundManager", wikiTruth_contracts_address.fundManager);
        const tx_fundManager = await fundManager.implementation();
        console.log("implementation():", tx_fundManager);
        // const tx_fundManager = await fundManager.serviceFeeRate();
        // console.log("serviceFeeRate:", tx_fundManager);
        // const tx_fundManager2 = await fundManager.helperRewardRate();
        // console.log("helperRewardRate:", tx_fundManager2);
        await new Promise(resolve => setTimeout(resolve, 5000));
    }

    if (contracts.includes('TruthBox')) {
        console.log("   3.3 读取 TruthBox...");
        const truthBox = await ethers.getContractAt("TruthBox", wikiTruth_contracts_address.truthBox);
        const tx_truthBox = await truthBox.implementation();
        console.log("implementation():", tx_truthBox);
        // const tx_truthBox = await truthBox.incrementRate();
        // console.log("incrementRate:", tx_truthBox);
        // const tx_truthBox2 = await truthBox.nextBoxId();
        // console.log("nextBoxId:", tx_truthBox2);
        await new Promise(resolve => setTimeout(resolve, 5000));
    }

    // console.log("   3.6 设置 UserId...");
    // const userId = await ethers.getContractAt("UserId", wikiTruth_testnet_address.userId);
    // const userId = userId.connect(adminSigner) as any;
    // const tx7 = await userId.;
    // await tx7.wait();

    if (contracts.includes('TruthNFT')) {
        console.log("   3.4 读取 TruthNFT...");
        const truthNFT = await ethers.getContractAt("TruthNFT", wikiTruth_contracts_address.truthNFT);
        const tx_truthNFT = await truthNFT.implementation();
        console.log("implementation():", tx_truthNFT);
        // const tx5 = await truthNFT.setNetwork("ipfs://", "sf");
        // await tx5.wait();
        // console.log("   3.4.1 设置 TruthNFT完成");
        // await new Promise(resolve => setTimeout(resolve, 5000));
    }

    if (contracts.includes('SiweAuth')) {
        console.log("   3.5 读取 SiweAuth...");
        const siweAuth = await ethers.getContractAt("SiweAuthWikiTruth", wikiTruth_contracts_address.siweAuth);
        // const tx_siweAuth = await siweAuth.domain();
        // console.log("domain:", tx_siweAuth);
        const tx_siweAuth2 = await siweAuth.allDomains();
        console.log("allDomains:", tx_siweAuth2);
        // allDomains: Result(7) [
        //     'wikitruth.eth.limo',
        //     'localhost:5173',
        //     'localhost',
        //     'localhost:3000',
        //     'wikitruth.xyz',
        //     'app.wikitruth.xyz',
        //     'app.wikitruth.eth.limo'
        //   ]
        await new Promise(resolve => setTimeout(resolve, 5000));
    }

    console.log("\n所有合约数据读取完成");


    // =========================================== View functions=============================================

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
