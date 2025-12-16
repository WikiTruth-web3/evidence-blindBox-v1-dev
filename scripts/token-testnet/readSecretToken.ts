import { ethers } from "hardhat";
import {formatUnits} from "ethers";
// import {
//     user_evm_WikiTruth
// } from "../../WikiTruth_account";
import { wikiTruth_contracts_address, wikiTruth_testnet_contracts } from "../utils/wikiTruth_contracts_address";
// import { getSiweMsg, erc191sign  } from "../utils/SiweAuth";
import { PermitType, signEIP712, buildEIP712Permit } from "../utils/eip712-simple";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";

/**
 * 
 * @returns 读取WROSESecret合约数据
 * 
 * 运行命令：npx hardhat run scripts/token-testnet/readSecretToken.ts --network sapphire-testnet
 */

async function main() {
    console.log("开始读取WROSESecret合约数据...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 网络ID:", network.chainId);
    if (Number(network.chainId) !== 23295 ) {
        console.error("networkId is not 23295");
        return;
    }

    const { adminSigner } = await getSigners_SapphireTestnet();
    if (!adminSigner) {
        console.error("signer不存在");
        return;
    }

    const wroseSecretContract = wikiTruth_testnet_contracts.find(c => c.symbol === "wROSE.S");
    const officialTokenSecretContract = wikiTruth_testnet_contracts.find(c => c.symbol === "WTRC.S");

    if (!wroseSecretContract || !officialTokenSecretContract) {
        console.error("wroseSecret or officialTokenSecret is not set");
        return;
    }

    const CONTRACTS = [wroseSecretContract, officialTokenSecretContract];

    const spender = adminSigner.address;

    let permits: any[] = [];
    for (const contract of CONTRACTS) {
        const permit = await buildEIP712Permit(
            adminSigner, 
            spender, 
            BigInt(0), 
            PermitType.View, 
            contract.address, 
        )
        permits.push(permit);
    }
    // =========================================== View functions=============================================

    for (let i = 0; i < CONTRACTS.length; i++) {
        const contract = CONTRACTS[i];

        const permit = permits[i];
        if (!permit) {
            console.error("permit not found");
            return;
        }
        const factory = await ethers.getContractAt(contract.contract, contract.address);
        const tx_balanceOf = await factory.balanceOfWithPermit(permit)
        console.log(`balanceOf_${contract.symbol}:`, formatUnits(tx_balanceOf, 18));
        await new Promise(resolve => setTimeout(resolve, 5000));
    }

//     balanceOf_wROSE.S: 20299.99999999999999997
//     balanceOf_WTRC.S: 99991639.999999999999999999

//     再次在uniswapV3中 交易 10000 WTRC.S 到 wROSE.S （池子： ）

// balanceOf_wROSE.S: 19298.700000000018757514
// balanceOf_WTRC.S:  99981629.999999999999999999
// balanceOf_WTRC.S: 100001689.636999999997150022

//     再次在uniswapV3中 交易 10 WTRC.S 到 wROSE.S （池子： ）
// balanceOf_wROSE.S: 20299.99999999999999997

    // const wroseSecret = await ethers.getContractAt("WROSEsecret", wroseSecretContract.address);
    // const officialTokenSecret = await ethers.getContractAt("ERC20Secret", officialTokenSecretContract.address);


    // const tx_wroseSecret = await wroseSecret.DOMAIN_SEPARATOR()
    // console.log("DOMAIN_SEPARATOR_WROSESecret:", tx_wroseSecret);
    // await new Promise(resolve => setTimeout(resolve, 5000));
    // DOMAIN_SEPARATOR_WROSESecret: 0xb88a0cadf2e854909724ef07cc6dfdb6824fe2f5c432aab9c028f2953677a581

    // console.log("   2. 读取 OfficialTokenSecret的数据...");
    // const tx_officialTokenSecret = await officialTokenSecret.DOMAIN_SEPARATOR()
    // console.log("DOMAIN_SEPARATOR_OfficialTokenSecret:", tx_officialTokenSecret);
    // await new Promise(resolve => setTimeout(resolve, 5000));

// DOMAIN_SEPARATOR_OfficialTokenSecret: 0x7093cef7e260da9e4daa96cf8f70a9dfca355dec087821ad93cae08101d1c899



}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
    