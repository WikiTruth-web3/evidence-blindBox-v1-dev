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
 * 运行命令：npx hardhat run scripts/token-testnet/wrap.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始将ERC20代币包装为Secret ERC20代币...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("networkId is not 23295");
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

    const erc20 = await ethers.getContractAt(contractERC20.contract, mockTokenAddress);
    // 1. 检查授权，如果授权不足，则授权
    const allowance = await erc20.allowance(user.address, secretTokenAddress);
    if (allowance < amount_wrap) {
        await erc20.approve(secretTokenAddress, ethers.MaxUint256);
    }

    await new Promise(resolve => setTimeout(resolve, 10000));

    console.log(`\n3. ${secretTokenName} 合约wrap ERC20代币...`);
    const secretToken = await ethers.getContractAt(contractSercet.contract, secretTokenAddress);
    await secretToken.wrap(amount_wrap);
    console.log(`${secretTokenName} 合约代币wrap完成`);

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
