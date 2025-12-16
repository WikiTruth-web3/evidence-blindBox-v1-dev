import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address , wikiTruth_testnet_contracts } from "../utils/wikiTruth_contracts_address";
import { v3_core_testnet_address, v3_periphery_testnet_address } from "../utils/v3_testnet_address";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
// import { domainList } from "../../test/utils";

/**
 * 
 * @returns 初始化WikiTruth的合约至sapphire-testnet测试网
 * 
 * run：npx hardhat run scripts/wikiTruth-testnet/00_initAllContracts.ts --network sapphire-testnet
 * 
 * 第一步：在所有合约中设置AddressManager地址
 */

// 需要更新的合约列表
const contracts = [
    // 'AddressManager',
    'Exchange',
    'FundManager',
    'TruthBox',
    'TruthNFT',
    'UserId',
    // 'SiweAuth',
    // 'Dao',
    // 'governance',
    // 'daoFundManager',
    // 'none', // TODO 将none激活，这样可以避免脚本被误执行
]


async function main() {
    console.log("开始初始化WikiTruth的所有合约，不包括AddressManager...");

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

    if (contracts.includes('none')) {
        console.error("没有需要升级的合约");
        return;
    }

    const addressManager = wikiTruth_testnet_contracts.find(c => c.name === 'AddressManager')?.address;
    if (!addressManager) {
        console.error("AddressManager的代理合约地址不存在");
        return;
    }

    // =====================================================================
    console.log("\n1. 设置各个合约的AddressManager地址...");
    for (const contract of contracts) {
        const contractAddress = wikiTruth_testnet_contracts.find(c => c.name === contract)?.address;
        if (!contractAddress) {
            console.error(`${contract}的代理合约地址不存在`);
            continue;
        }
        const contractInstance = await ethers.getContractAt(contract, contractAddress);
        // const contract_admin = contractInstance.connect(adminSigner) as any;
        const tx = await contractInstance.setAddressManager(addressManager);
        await tx.wait();
        console.log(`${contract}的AddressManager地址设置完成`);

        await new Promise(resolve => setTimeout(resolve, 5000));
    }
    console.log("\n所有合约的AddressManager地址设置完成");

    // =====================================================================
    // console.log("\n2. 设置各个合约的地址...");
    // for (const contract of contracts) {
    //     const contractAddress = wikiTruth_testnet_contracts.find(c => c.name === contract)?.address;
    //     if (!contractAddress) {
    //         console.error(`${contract}的代理合约地址不存在`);
    //         continue;
    //     }
    //     const contractInstance = await ethers.getContractAt(contract, contractAddress);
    //     // 链接signer并调用（使用类型断言）
    //     const contract_admin = contractInstance.connect(adminSigner) as any;
    //     const tx = await contract_admin.setAddress();
    //     await tx.wait();
    //     console.log(`${contract}地址设置完成`);

    //     await new Promise(resolve => setTimeout(resolve, 5000));
    // }
    // console.log("\n所有合约地址设置完成");


    // =========================================== View functions=============================================

}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
    