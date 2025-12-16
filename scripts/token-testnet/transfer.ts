import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
const fs = require('fs');
const path = require('path');
/**
 * 
 * @returns 部署Truth Market Coin和ERC20Private6合约至sapphire-testnet测试网
 * 
 * 运行命令：npx hardhat run scripts/token-testnet/transfer.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始转移ERC20代币...");
    
    const user_from = user_evm_WikiTruth.admin;
    console.log("部署账户:", user_from.address);
    const user_to = user_evm_WikiTruth.buyer;
    console.log("接收账户:", user_to.address);

    if (!user_from.address) {
        console.error("部署账户不存在");
        return;
    }

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    // 1. 转移ERC20代币
    console.log("\n1. 转移ERC20代币...");
    const mockToken = await ethers.getContractAt("MockERC20", contract.address);
    await mockToken.transfer(user_to.address, amount_transfer);

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("部署失败:", error);
        process.exit(1);
    });
