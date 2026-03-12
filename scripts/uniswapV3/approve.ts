import { ethers } from "hardhat";
import {
    v3_core_testnet_address,
    v3_periphery_testnet_address,
} from "../utils/v3_testnet_address";
import { wikiTruth_contracts_address, wikiTruth_testnet_contracts } from "../utils/contracts_address";
const fs = require('fs');
const path = require('path');
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";


/**
 * 
 * @returns 授权ERC20代币给Uniswap V3合约至sapphire-testnet测试网
 * 
 * 运行命令：npx hardhat run scripts/uniswapV3/approve.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始添加Uniswap V3池子...");
    
    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("networkId is not 23295");
        return;
    }
    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("signer不存在");
        return;
    }
    const contractSecret_officialToken = wikiTruth_testnet_contracts.find(c => c.name === "OfficialToken_ERC20Secret");
    const contractSecret_wroseSecret = wikiTruth_testnet_contracts.find(c => c.name === "WROSESecret");
    if (!contractSecret_officialToken || !contractSecret_wroseSecret) {
        console.error(`合约不存在`);
        return;
    }

    // 2. wrap ERC20代币
    // await mockToken.approve(privateTokenAddress, ethers.parseUnits("1000000000", 18));
    const secretToken_officialToken = await ethers.getContractAt("ERC20Secret", contractSecret_officialToken.address);
    const secretToken_wroseSecret = await ethers.getContractAt("ERC20Secret", contractSecret_wroseSecret.address);

    // TODO 20251213
    await secretToken_officialToken.approve(v3_periphery_testnet_address.nftPositionManager, ethers.MaxUint256);
    await secretToken_wroseSecret.approve(v3_periphery_testnet_address.nftPositionManager, ethers.MaxUint256);
    console.log("代币授权给Uniswap V3完成");
    await new Promise(resolve => setTimeout(resolve, 5000));

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("部署失败:", error);
        process.exit(1);
    });
