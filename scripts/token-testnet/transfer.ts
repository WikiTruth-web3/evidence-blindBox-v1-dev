import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
import { parseUnits } from "ethers";
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

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    const signers = await getSigners_SapphireTestnet()

    const user_from = signers.adminSigner

    const users_to = [signers.buyerSigner, signers.buyer2Signer]

    if (!user_from) {
        console.error("部署账户不存在");
        return;
    }

    for (const user of users_to) {
        if (!user) {
            console.error("接收账户不存在");
            return;
        }

    }

    const erc20_address = wikiTruth_contracts_address.officialToken;

    const amount = parseUnits("50000", 18);

    // 1. 转移ERC20代币
    console.log("\n1. 转移ERC20代币...");
    const mockToken = await ethers.getContractAt("MockERC20", erc20_address);
    const mockToken_from = mockToken.connect(user_from);

    for (const user of users_to) {
        const address = user?.getAddress();
        if (!address) {
            console.error("接收账户不存在");
            return;
        }
        await mockToken_from.transfer(address, amount);
        console.log(`transfer_${amount} to ${address} success`);
        await new Promise(resolve => setTimeout(resolve, 8000));
    }

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("部署失败:", error);
        process.exit(1);
    });


    