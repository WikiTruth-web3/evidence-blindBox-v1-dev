import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
import { v3_core_testnet_address, v3_periphery_testnet_address } from "../utils/v3_testnet_address";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
// import { domainList } from "../../test/utils";

/**
 * 
 * @returns 初始化WikiTruth的合约至sapphire-testnet测试网
 * 
 * 1. 设置AddressManager的地址列表
 * 2. 设置所有的合约地址
 * 3. 设置OfficialToken
 * 4. 添加WROSESecret为支持的代币
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/01_initAddressManager.ts --network sapphire-testnet
 */


async function main() {
    console.log("开始初始化WikiTruth的AddressManager...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    const adminAddress = user_evm_WikiTruth.admin.address;
    const daoFundManagerAddress = user_evm_WikiTruth.daoFundManager.address;

    if (!adminAddress || !daoFundManagerAddress) {
        console.error("adminAddress或daoFundManagerAddress不存在");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("adminSigner不存在");
        return;
    }

    console.log("\n1. 获取AddressManager合约...");
    const addressManager = await ethers.getContractAt("AddressManager", wikiTruth_contracts_address.addressManager);
    // const addressManager_admin = addressManager.connect(adminSigner) as any;

    /**
     * @dev 设置AddressManager的地址列表
     * @param contractList 合约列表
     * @returns 设置完成
     * [
        dao, 
        governance, 
        daoFundManager, 
        userId, 
        siweAuth, 
        truthBox, 
        truthNFT, 
        exchange, 
        fundManager, 
        swapContract,
        quoter
        ]

     */
    const contractList: string[] = [
        adminAddress, // dao, 暂时使用admin地址
        ethers.ZeroAddress, // governance, 暂时不设置
        daoFundManagerAddress, // daoFundManager, 暂时使用admin地址
        wikiTruth_contracts_address.userId, // userId, 
        wikiTruth_contracts_address.siweAuth, // siweAuth, 
        wikiTruth_contracts_address.truthBox, // truthBox, 
        wikiTruth_contracts_address.truthNFT, // truthNFT, 
        wikiTruth_contracts_address.exchange, // exchange, 
        wikiTruth_contracts_address.fundManager, // fundManager, 
        v3_periphery_testnet_address.swapRouter, // swapContract, 使用uniswapV3的SwapRouter
        v3_periphery_testnet_address.quoter, // quoter, 使用uniswapV3的Quoter
    ]

    if (contractList.length !== 11) {
        console.error("contractList的长度不正确");
        return;
    }

    // =========================== Write functions ==================================
    console.log("\n2. 设置AddressManager的地址列表...");
    const tx1 = await addressManager.setAddressList(contractList);
    await tx1.wait();
    console.log("AddressManager的地址列表设置完成");
    await new Promise(resolve => setTimeout(resolve, 8000));

    // console.log("\n3. 设置OfficialToken...");
    // await addressManager.setOfficialToken(wikiTruth_contracts_address.officialToken_Secret);
    // console.log("\nOfficialToken设置完成");
    // await new Promise(resolve => setTimeout(resolve, 5000));

    // console.log("\n4. 添加代币...");
    // await addressManager.addToken(wikiTruth_contracts_address.officialToken_Secret);
    // console.log("\nOfficialToken添加为支持的代币完成");
    // await new Promise(resolve => setTimeout(resolve, 8000));

    // await addressManager.addToken(wikiTruth_contracts_address.wroseSecret);
    // console.log("\nWROSESecret添加为支持的代币完成");
    // await new Promise(resolve => setTimeout(resolve, 8000));

    // await addressManager.removeToken(wikiTruth_contracts_address.wroseSecret);
    // console.log("\n移除为支持的代币完成");
    // await new Promise(resolve => setTimeout(resolve, 8000));

    // console.log("\n5. 交互setAllAddress...");
    // const tx2 = await addressManager.setAllAddress();
    // await tx2.wait();
    // console.log("AddressManager的setAllAddress完成");
    // await new Promise(resolve => setTimeout(resolve, 8000));

    // =========================================== View functions=============================================

    // console.log("\nAddressManager的地址列表:");
    // console.log("dao:", await addressManager.dao());
    // console.log("governance:", await addressManager.governance());
    // console.log("daoFundManager:", await addressManager.daoFundManager());
    // await new Promise(resolve => setTimeout(resolve, 5000));
    // console.log("userId:", await addressManager.userId());
    // console.log("siweAuth:", await addressManager.siweAuth());
    // console.log("truthBox:", await addressManager.truthBox());
    // await new Promise(resolve => setTimeout(resolve, 5000));
    // console.log("truthNFT:", await addressManager.truthNFT());
    // console.log("exchange:", await addressManager.exchange());
    // console.log("fundManager:", await addressManager.fundManager());
    // await new Promise(resolve => setTimeout(resolve, 5000));
    // console.log("swapContract:", await addressManager.swapContract());
    // console.log("quoter:", await addressManager.quoter());

    // await new Promise(resolve => setTimeout(resolve, 5000));

    // console.log("\nAddressManager的官方代币:");
    // console.log("officialToken:", await addressManager.officialToken());
    // console.log("isOfficialToken:", await addressManager.isTokenSupported(wikiTruth_contracts_address.wroseSecret));

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
    