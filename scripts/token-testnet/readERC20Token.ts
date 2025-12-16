import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address, wikiTruth_testnet_contracts } from "../utils/wikiTruth_contracts_address";
import { getSiweMsg, erc191sign } from "../utils/SiweAuth";
import { PermitType, signEIP712 } from "../utils/eip712-simple";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";

/**
 * 
 * @returns 读取ERC20Token合约数据
 * 
 * 运行命令：npx hardhat run scripts/token-testnet/readERC20Token.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始读取ERC20Token合约数据...");



    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295) {
        console.error("networkId is not 23295");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("signer不存在");
        return;
    }



    const contractERC20 = wikiTruth_testnet_contracts.find(c => c.name === "OfficialToken");
    if (!contractERC20) {
        console.error(`合约不存在`);
        return;
    }
    const erc20TokenAddress = contractERC20.address;
    const erc20TokenName = contractERC20.name;

    const spender = adminSigner.address;
    // const amount = ethers.parseUnits("1000000000", 18);

    // ======================== Config parameters =========================

    const users = [
        adminSigner,
        // buyerSigner, 
        // sellerSigner, 
        // minterSigner, 
    ];
    const functions = [
        // "balanceOf",
        "allowance",
    ]

    // =========================================== View functions=============================================

    const erc20Token = await ethers.getContractAt("ERC20Token", erc20TokenAddress);

    for (let i = 0; i < users.length; i++) {
        const user = users[i];

        if (functions.includes("balanceOf")) {
            const tx_balanceOf = await erc20Token.balanceOf(user.address)
            console.log(`${i+1}. balanceOf_ERC20Token:`, tx_balanceOf);
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
        if (functions.includes("allowance")) {
            const tx_allowance = await erc20Token.allowance(user.address, spender)
            console.log(`${i+1}. allowance_ERC20Token:`, tx_allowance);
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
    }
}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
