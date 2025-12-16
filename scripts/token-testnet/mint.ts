import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { wikiTruth_contracts_address, wikiTruth_testnet_contracts } from "../utils/wikiTruth_contracts_address";
const fs = require('fs');
const path = require('path');

/**
 * 
 * @returns mint和wrap ERC20代币
 * 
 * 运行命令：npx hardhat run scripts/token-testnet/mint-wrap.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始mint和wrap ERC20代币...");

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

    const user = adminSigner

    const amount_wrap = ethers.parseUnits("1000", 18);

    const contractERC20 = wikiTruth_testnet_contracts.find(c => c.name === "OfficialToken");
    if (!contractERC20) {
        console.error(`合约不存在`);
        return;
    }
    const mockTokenAddress = contractERC20.address;
    const mockTokenName = contractERC20.name;

    const contractSercet = wikiTruth_testnet_contracts.find(c => c.name === "OfficialToken_ERC20Secret");
    if (!contractSercet) {
        console.error(`合约不存在`);
        return;
    }
    const secretTokenAddress = contractSercet.address;
    const secretTokenName = contractSercet.name;
    
    // 1. mint ERC20代币
    console.log(`\n1. ${mockTokenName} 合约mint ERC20代币...`);
    const mockToken = await ethers.getContractAt(contractERC20.contract, mockTokenAddress);
    await mockToken.mintAdmin();
    // await mockToken.mint(user.address);
    console.log(`${mockTokenName} 合约ERC20代币mint完成`);

    await new Promise(resolve => setTimeout(resolve, 10000));
}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
