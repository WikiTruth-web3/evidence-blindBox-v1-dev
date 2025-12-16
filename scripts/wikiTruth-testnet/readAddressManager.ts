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
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/readAddressManager.ts --network sapphire-testnet
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


    console.log("\n3. 设置各个合约的数据...");
    console.log("   3.1 读取 AddressManager...");
    const addressManager = await ethers.getContractAt("AddressManager", wikiTruth_contracts_address.addressManager);
    // const tx_addressManager = await addressManager.getTokenList();
    // console.log("addressManager_tokenList :", tx_addressManager);
    const tx_addressManager = await addressManager.officialToken();
    console.log("addressManager_officialToken() :", tx_addressManager);
    // await new Promise(resolve => setTimeout(resolve, 5000));

    //   '0x449e2CD61F0328Ae68f4A530170C892B45b4B269',
    //   '0xDf698806B03C54e9CafE81caCaE54Ce1727DD134',
    //   '0x4e30337908E19917f3F74adB45966114A55205c2'
    // const tx_0 = await addressManager.isTokenSupported('0x449e2CD61F0328Ae68f4A530170C892B45b4B269');
    // console.log("addressManager_tx0 :", tx_0);
    // const tx_1 = await addressManager.isTokenSupported('0xDf698806B03C54e9CafE81caCaE54Ce1727DD134');
    // console.log("addressManager_tx1 :", tx_1);
    // const tx_2 = await addressManager.isTokenSupported('0x449e2CD61F0328Ae68f4A530170C892B45b4B269');
    // console.log("addressManager_tx2 :", tx_2);
    // await new Promise(resolve => setTimeout(resolve, 5000));

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
    