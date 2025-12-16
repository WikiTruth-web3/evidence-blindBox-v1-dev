import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
// import { v3_core_testnet_address, v3_periphery_testnet_address } from "../utils/v3_testnet_address";
// import { domainList } from "../../test/utils";

/**
 * 
 * @returns 初始化WikiTruth的合约至sapphire-testnet测试网
 * 
 * 1. 设置SiweAuthWikiTruth的PrimaryDomain
 * 2. 设置SiweAuthWikiTruth的Domains
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/SiweAuth_domain.ts --network sapphire-testnet
 */

// NOTE 在部署合约时，已经完成了PrimaryDomain和Domains的设置
// 所以不需要初始化这个合约。

const primaryDomain = "wikitruth.eth.limo";
const domains = [
    // "none", // 不添加任何域名, 每次成功添加后，将none激活，这样可以避免脚本被误执行
    // "truthwiki.eth.limo", // 已经添加
    "localhost",
    "localhost:3000",
];

const domains_remove = [
    "none", // NOTE 不删除任何域名, 每次成功删除后，将none激活，这样可以避免脚本被误执行
    // "localhost:3000",
];


async function main() {
    console.log("开始初始化WikiTruth的SiweAuthWikiTruth...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    // let adminAddress = '';

    // if (!adminAddress) {
    //     console.error("adminAddress不存在");
    //     return;
    // }

    console.log("\n1. 获取SiweAuthWikiTruth合约...");
    const siweAuth = await ethers.getContractAt("SiweAuthWikiTruth", wikiTruth_contracts_address.siweAuth);

    // =========================== Write functions ==================================
    // console.log("\n2. 设置SiweAuthWikiTruth的PrimaryDomain...");
    // await siweAuth.setPrimaryDomain(primaryDomain);
    // console.log("\nSiweAuthWikiTruth的PrimaryDomain设置完成");

    await new Promise(resolve => setTimeout(resolve, 5000));

    if (domains.includes('none')) {
        console.error("没有需要添加的域名");
        return;
    } else {
        console.log("\n3. 设置SiweAuthWikiTruth的Domains...");
        for (const domain of domains) {
            await siweAuth.addDomain(domain);
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
        console.log("\nSiweAuthWikiTruth的Domains设置完成");
    }

    await new Promise(resolve => setTimeout(resolve, 5000));

    if (domains_remove.includes('none')) {
        console.error("没有需要删除的域名");
        return;
    } else {
        console.log("\n4. 删除SiweAuthWikiTruth的Domains...");
        for (const domain of domains_remove) {
            await siweAuth.removeDomain(domain);
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
        console.log("\nSiweAuthWikiTruth的Domains删除完成");
    }

    await new Promise(resolve => setTimeout(resolve, 5000));

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
