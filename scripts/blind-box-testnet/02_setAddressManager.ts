import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import main_contracts_address from "../../deployments/main_contracts_testnet.json"

/**
 * 多个合约批量管理操作: setAddressManager / setAdmin
 * 运行命令：npx hardhat run scripts/blind-box-testnet/02_setAddressManager.ts --network sapphire-testnet
 */

type ContractTarget = {
    name: string; // artifact name
    address: string;
    setAdminAddressManager: boolean;
    setAdmin: boolean;
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
    const addressManagerAddr = main_contracts_address.AddressManager;
    const DO_SET_ADDRESS_MANAGER = true;
    // const DO_SET_ADMIN = false; 

    if (!ethers.isAddress(addressManagerAddr)) {
        throw new Error(`AddressManager 地址无效: ${addressManagerAddr}`);
    }

    const targets: ContractTarget[] = [
        {
            name: "Forwarder",
            address: main_contracts_address.Forwarder,
            setAdminAddressManager: true,
            setAdmin: true,
        },
        {
            name: "BlindBox",
            address: main_contracts_address.BlindBox,
            setAdminAddressManager: true,
            setAdmin: true,
        },
        {
            name: "Exchange",
            address: main_contracts_address.Exchange,
            setAdminAddressManager: true,
            setAdmin: true,
        },
        {
            name: "FundManager",
            address: main_contracts_address.FundManager,
            setAdminAddressManager: true,
            setAdmin: true,
        },
        {
            name: "UserManager",
            address: main_contracts_address.UserManager,
            setAdminAddressManager: true,
            setAdmin: true,
        },
        // SiweAuthWikiTruth 只有 setAdmin（无 setAddressManager）
        {
            name: "SiweAuth",
            address: main_contracts_address.SiweAuth,
            setAdminAddressManager: false,
            setAdmin: true,
        },
        // AddressManager 本身只需要 setAdmin（一般不需要 setAddressManager）
        {
            name: "AddressManager",
            address: main_contracts_address.AddressManager,
            setAdminAddressManager: false,
            setAdmin: true,
        },
    ];

    for (const t of targets) {
        if (!ethers.isAddress(t.address)) {
            console.log(`⚠️ 跳过 ${t.name}，地址无效: ${t.address}`);
            continue;
        }

        console.log(`\n--- ${t.name} @ ${t.address} ---`);
        const contract = await ethers.getContractAt(t.name, t.address, signer);

        if (DO_SET_ADDRESS_MANAGER && t.setAdminAddressManager) {
            console.log(`调用 ${t.name}.setAddressManager(${addressManagerAddr})...`);
            const tx = await (contract as any).setAddressManager(addressManagerAddr);
            console.log(`tx: ${tx.hash}`);
            await tx.wait();
            console.log("✅ setAddressManager 完成");
        }

        

        // if (DO_SET_ADMIN && t.setAdmin) {
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