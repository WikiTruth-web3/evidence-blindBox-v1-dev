import { ethers } from "hardhat";
// import {
//     user_evm_WikiTruth
// } from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
// import { v3_core_testnet_address, v3_periphery_testnet_address } from "../utils/v3_testnet_address";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
// import { domainList } from "../../test/utils";

/**
 * 
 * @returns 读取WikiTruth的合约数据
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/writeExchange.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始交易...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    const { buyerSigner } = await getSigners_SapphireTestnet();
        if (!buyerSigner) {
            console.error("signer不存在");
            return;
        }
    
    const exchange = await ethers.getContractAt("Exchange", wikiTruth_contracts_address.exchange);
    const exchange_buyer = exchange.connect(buyerSigner) as any;

    const tx_1 = await exchange_buyer.bid(0);
    console.log("bid_0:", tx_1);
    await new Promise(resolve => setTimeout(resolve, 5000));

    // const tx_exchange = await exchange.refundRequestPeriod();
    // console.log("refundRequestPeriod:", tx_exchange);
    
    console.log("\n完成---------------");

    // =========================================== View functions=============================================

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
    