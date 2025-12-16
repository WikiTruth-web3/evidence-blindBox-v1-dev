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
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/readExchange.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始读取WikiTruth的所有合约数据...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }
    
    console.log("   3.1 读取 Exchange...");
    const exchange = await ethers.getContractAt("Exchange", wikiTruth_contracts_address.exchange);
    // const tx_exchange = await exchange.refundRequestPeriod();
    // console.log("refundRequestPeriod:", tx_exchange);
    // const tx_exchange2 = await exchange.refundReviewPeriod();
    // console.log("refundReviewPeriod:", tx_exchange2);
    // const tx_exchange3 = await exchange.bidIncrementRate();
    // console.log("bidIncrementRate:", tx_exchange3);

    // const tx_5 = await exchange.acceptedToken(5);
    // console.log("acceptedToken_5:", tx_5);
    // const tx_6 = await exchange.acceptedToken(6);
    // console.log("acceptedToken_5:", tx_6);
    // await new Promise(resolve => setTimeout(resolve, 5000));

    // const tx_exchange = await exchange.refundRequestPeriod();
    // console.log("refundRequestPeriod:", tx_exchange);

    const buyerOf_debug = await exchange.buyerOf_debug(0);
    console.log("buyerOf_debug_0:", buyerOf_debug);
    await new Promise(resolve => setTimeout(resolve, 5000));

    const acceptedToken = await exchange.acceptedToken(0);
    console.log("acceptedToken_0:", acceptedToken);
    await new Promise(resolve => setTimeout(resolve, 5000));

    console.log("\n完成");

    // =========================================== View functions=============================================

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
    