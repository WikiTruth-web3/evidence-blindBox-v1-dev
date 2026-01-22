import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address, wikiTruth_testnet_contracts } from "../utils/wikiTruth_contracts_address";
import { v3_core_testnet_address, v3_periphery_testnet_address } from "../utils/v3_testnet_address";
// import { domainList } from "../../test/utils";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";

/**
 * 
 * @returns 初始化WikiTruth的合约至sapphire-testnet测试网
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/upgrade.ts --network sapphire-testnet
 */

// 需要更新的合约列表
const nowList = [
    // 'AddressManager',
    'Exchange',
    'FundManager',
    'TruthBox',
    'TruthNFT',
    // 'UserId',
    // 'SiweAuth',
    // 'Dao',
    // 'governance',
    // 'daoFundManager',
    // 'none' // 不升级任何合约, 每次成功升级后，将此值改为none，这样可以避免脚本被误执行
]



async function main() {
    console.log("开始升级WikiTruth的合约...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("当前网络ID不是23295，请检查网络ID");
        return;
    }

    if (nowList.includes('none')) {
        console.error("没有需要升级的合约");
        return;
    } else {
        console.log("需要升级的合约列表:", nowList);
    }

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("adminSigner不存在");
        return;
    }

    console.log("\n3. 设置各个合约的地址（使用 admin 身份直接调用）...");
    
    for (const contract of nowList) {
        const proxy = wikiTruth_testnet_contracts.find(c => c.name === contract)?.address;
        if (!proxy) {
            console.error(`${contract}的代理合约地址不存在`);
            continue;
        }
        const implementation = wikiTruth_testnet_contracts.find(c => c.name === contract)?.implementation;
        if (!implementation) {
            console.error(`${contract}的实现合约地址不存在`);
            continue;
        }

        console.log(`${contract}的代理合约地址: ${proxy}`);
        console.log(`${contract}的实现合约地址: ${implementation}`);

        const contractInstance = await ethers.getContractAt(contract, proxy);
        // 链接signer
        const contract_admin = contractInstance.connect(adminSigner) as any;
        const tx = await contract_admin.upgrade(implementation);
        await tx.wait();
        console.log(`${contract}升级完成`);

        await new Promise(resolve => setTimeout(resolve, 5000));
    }
    console.log("\n所有合约升级完成");


    // =========================================== View functions=============================================

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
    