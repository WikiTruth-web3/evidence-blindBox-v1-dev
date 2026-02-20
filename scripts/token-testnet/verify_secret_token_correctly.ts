import { ethers } from "hardhat";
import { formatUnits } from "ethers";
import { wikiTruth_contracts_address, wikiTruth_testnet_contracts } from "../utils/wikiTruth_contracts_address";
import { PermitType, buildEIP712Permit } from "../utils/eip712-simple";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";

async function main() {
    console.log("Starting verification of Secret Token (WTRC.S)...");

    const network = await ethers.provider.getNetwork();
    console.log("🌐 Chain ID:", network.chainId);
    if (Number(network.chainId) !== 23295) {
        console.error("Network ID is not 23295 (Sapphire Testnet)");
        return;
    }

    const { buyerSigner } = await getSigners_SapphireTestnet();
    if (!buyerSigner) {
        console.error("buyerSigner not found");
        return;
    }

    const buyerAddress = await buyerSigner.getAddress();
    console.log("Buyer Address:", buyerAddress);

    const fundManagerAddress = wikiTruth_contracts_address.fundManager;
    const officialTokenSecretAddress = wikiTruth_contracts_address.officialToken_Secret;
    
    console.log("OfficialToken_Secret Address:", officialTokenSecretAddress);
    console.log("FundManager Address:", fundManagerAddress);

    const factory = await ethers.getContractAt("ERC20Secret", officialTokenSecretAddress);

    // 1. Check Balance with Permit
    // For view balance/allowance, spender is usually our own address or irrelevant as long as it matches the permit
    // In ERC20Secret.sol, the permit's owner is the one whose balance/allowance is checked.
    const balancePermit = await buildEIP712Permit(
        buyerSigner,
        buyerAddress, // spender (irrelevant for VIEW, but must match what we sign)
        BigInt(0),
        PermitType.View,
        officialTokenSecretAddress,
    );

    if (!balancePermit) {
        console.error("Failed to build balance permit");
        return;
    }

    const balance = await factory.balanceOfWithPermit(balancePermit);
    console.log("--- Secret Token Info ---");
    console.log(`Balance of Buyer: ${formatUnits(balance, 18)} WTRC.S`);

    // 2. Check Allowance with Permit
    const allowancePermit = await buildEIP712Permit(
        buyerSigner,
        fundManagerAddress, // spender (The contract we want to check allowance FOR)
        BigInt(0),
        PermitType.View,
        officialTokenSecretAddress,
    );

    if (!allowancePermit) {
        console.error("Failed to build allowance permit");
        return;
    }

    const allowance = await factory.allowanceWithPermit(allowancePermit);
    console.log(`Allowance to FundManager: ${formatUnits(allowance, 18)} WTRC.S`);

    // 3. Check Box 15 Price
    const truthBox = await ethers.getContractAt("TruthBox", wikiTruth_contracts_address.truthBox);
    const boxId = 15;
    const price = await truthBox.getPrice(boxId);
    console.log(`Box 15 Price: ${formatUnits(price, 18)} WTRC.S`);

    if (balance < price) {
        console.log("❌ Error: Insufficient balance!");
    } else if (allowance < price) {
        console.log("❌ Error: Insufficient allowance!");
    } else {
        console.log("✅ Balance and Allowance are sufficient for the secret token.");
    }
}

main().catch(console.error);
