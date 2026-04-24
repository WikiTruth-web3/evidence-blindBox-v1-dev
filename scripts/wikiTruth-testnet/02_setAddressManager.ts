import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { core_contracts_address } from "../utils/contracts_address";

/**
 * 多个合约批量管理操作: setAddressManager / setAdmin
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/02_setAddressManager.ts --network sapphire-testnet
 */

type ContractTarget = {
    name: string; // artifact name
    address: string;
    supportsSetAddressManager: boolean;
    supportsSetAdmin: boolean;
};

async function main() {
    console.log("🚀 开始执行批量 setAddressManager / setAdmin ...");

    const network = await ethers.provider.getNetwork();
    if (Number(network.chainId) !== 23295) {
        console.error("当前网络ID不是23295，请检查网络配置");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();
    const signer = adminSigner;

    if (!signer) {
        console.error("未找到有效的签名者");
        return;
    }

    // ========= 可配置参数 =========
    const addressManagerAddr = core_contracts_address.addressManager;
    const newAdminAddr = signer.address; // 如需转移权限，改成目标管理员地址
    const DO_SET_ADDRESS_MANAGER = true;
    // const DO_SET_ADMIN = false; 

    if (!ethers.isAddress(addressManagerAddr)) {
        throw new Error(`AddressManager 地址无效: ${addressManagerAddr}`);
    }
    if (!ethers.isAddress(newAdminAddr)) {
        throw new Error(`newAdmin 地址无效: ${newAdminAddr}`);
    }

    const targets: ContractTarget[] = [
        {
            name: "Forwarder",
            address: core_contracts_address.forwarder,
            supportsSetAddressManager: true,
            supportsSetAdmin: true,
        },
        {
            name: "TruthBox",
            address: core_contracts_address.truthBox,
            supportsSetAddressManager: true,
            supportsSetAdmin: true,
        },
        {
            name: "Exchange",
            address: core_contracts_address.exchange,
            supportsSetAddressManager: true,
            supportsSetAdmin: true,
        },
        {
            name: "FundManager",
            address: core_contracts_address.fundManager,
            supportsSetAddressManager: true,
            supportsSetAdmin: true,
        },
        {
            name: "UserManager",
            address: core_contracts_address.userManager,
            supportsSetAddressManager: true,
            supportsSetAdmin: true,
        },
        // SiweAuthWikiTruth 只有 setAdmin（无 setAddressManager）
        {
            name: "SiweAuthWikiTruth",
            address: core_contracts_address.siweAuth,
            supportsSetAddressManager: false,
            supportsSetAdmin: true,
        },
        // AddressManager 本身只需要 setAdmin（一般不需要 setAddressManager）
        {
            name: "AddressManager",
            address: core_contracts_address.addressManager,
            supportsSetAddressManager: false,
            supportsSetAdmin: true,
        },
    ];

    for (const t of targets) {
        if (!ethers.isAddress(t.address)) {
            console.log(`⚠️ 跳过 ${t.name}，地址无效: ${t.address}`);
            continue;
        }

        console.log(`\n--- ${t.name} @ ${t.address} ---`);
        const contract = await ethers.getContractAt(t.name, t.address, signer);

        if (DO_SET_ADDRESS_MANAGER && t.supportsSetAddressManager) {
            console.log(`调用 ${t.name}.setAddressManager(${addressManagerAddr})...`);
            const tx = await (contract as any).setAddressManager(addressManagerAddr);
            console.log(`tx: ${tx.hash}`);
            await tx.wait();
            console.log("✅ setAddressManager 完成");
        }

        

        // if (DO_SET_ADMIN && t.supportsSetAdmin) {
        //     console.log(`调用 ${t.name}.setAdmin(${newAdminAddr})...`);
        //     const tx = await (contract as any).setAdmin(newAdminAddr);
        //     console.log(`tx: ${tx.hash}`);
        //     await tx.wait();
        //     console.log("✅ setAdmin 完成");
        // }
    }

    console.log("\n✅ 批量 setAddressManager / setAdmin 执行完成");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("执行过程出错:", error);
        process.exit(1);
    });