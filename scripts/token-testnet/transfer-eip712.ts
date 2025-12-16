import { ethers } from "hardhat";
import { user_evm_WikiTruth } from "../../WikiTruth_account";
import { wikiTruth_testnet_contracts } from "../utils/wikiTruth_contracts_address";
import { signEIP712, buildEIP712Permit, PermitType } from "../utils/eip712-simple";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
/**
 * EIP712转账脚本
 * 1. 用户from签名EIP712（transfer类型）
 * 2. 用户write使用该签名进行交互，将资金发送给toAddress
 * 
 * 运行命令：npx hardhat run scripts/token-testnet/transfer-eip712.ts --network sapphire-testnet
 */

async function main() {
    console.log("🔐 开始EIP712转账流程...");

    const network = await ethers.provider.getNetwork();
    console.log("🌐 网络ID:", network.chainId);
    if (Number(network.chainId) !== 23294 && Number(network.chainId) !== 23295) {
        console.error("❌ networkId is not 23294 or 23295");
        return;
    }

    const signers = await getSigners_SapphireTestnet();
    const signer_from = signers.adminSigner;  // 签名者（资金发送方）
    const signer_write = signers.minterSigner; // 执行者（调用合约的用户）
    const signer_to = signers.buyerSigner; // 接收者地址

    // 3. 验证账户
    if (!signer_from || !signer_from.address) {
        console.error("❌ 用户from账户不存在");
        return;
    }
    if (!signer_write || !signer_write.address) {
        console.error("❌ 用户write账户不存在");
        return;
    }
    if (!signer_to || !signer_to.address) {
        console.error("❌ 接收者地址不存在");
        return;
    }

    const amount_transfer = ethers.parseUnits("100", 18);

    // 2. 获取合约信息
    const contract2 = wikiTruth_testnet_contracts.find(c => c.name === "OfficialToken_ERC20Secret");
    if (!contract2) {
        console.error(`❌ 合约不存在`);
        return;
    }
    const secretTokenAddress = contract2.address;


    // 6. 检查发送方余额
    const secretToken = await ethers.getContractAt(contract2.contract, secretTokenAddress);

    // 7. 生成EIP712签名（用户from签名）
    console.log("\n🔐 步骤1: 用户from生成EIP712签名...");
    const permit = await buildEIP712Permit(
        signer_from,
        signer_to.address, // 在transfer中，spender就是接收者地址
        amount_transfer,
        PermitType.Transfer,
        secretTokenAddress,
    );

    console.log("\n📤 步骤2: 用户write使用签名执行转账...");

    // 使用write账户连接合约并调用transferWithPermit
    const secretTokenWithWrite = secretToken.connect(signer_write) as any;
    const tx = await secretTokenWithWrite.transferWithPermit(permit);
    // const tx = await secretToken.transferWithPermit(permit);
    console.log(`   交易哈希: ${tx.hash}`);

    console.log("⏳ 等待交易确认...");
    const receipt = await tx.wait();
    console.log(`✅ 交易确认成功！区块号: ${receipt.blockNumber}`);

    console.log("\n✅ EIP712转账流程完成！");
}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
