import { ethers } from "hardhat";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";

async function main() {
    const truthBoxAddress = wikiTruth_contracts_address.truthBox;
    const fundManagerAddress = wikiTruth_contracts_address.fundManager;
    const officialTokenAddress = wikiTruth_contracts_address.officialToken;
    
    const truthBox = await ethers.getContractAt("TruthBox", truthBoxAddress);
    const { buyerSigner } = await getSigners_SapphireTestnet();
    if (!buyerSigner) {
        console.error("signer不存在");
        return;
    }
    const buyerAddress = await buyerSigner.getAddress();
    
    console.log("Buyer Address:", buyerAddress);

    const boxId = 15;
    const [status, price, deadline] = await truthBox.getBasicData(boxId);
    
    console.log("--- Box 15 status ---");
    console.log("Status:", status.toString());
    console.log("Price:", ethers.formatEther(price), "Official Token");

    const token = await ethers.getContractAt("IERC20", officialTokenAddress);
    const balance = await token.balanceOf(buyerAddress);
    const allowance = await token.allowance(buyerAddress, fundManagerAddress);

    console.log("--- Token Info ---");
    console.log("Official Token:", officialTokenAddress);
    console.log("Balance:", ethers.formatEther(balance));
    console.log("Allowance to FundManager:", ethers.formatEther(allowance));
    console.log("FundManager Address:", fundManagerAddress);

    if (allowance < price) {
        console.log("❌ Error: Allowance is less than the required fee!");
        console.log("Required:", ethers.formatEther(price));
        console.log("Current Allowance:", ethers.formatEther(allowance));
    } else {
        console.log("✅ Allowance is sufficient.");
    }

    if (balance < price) {
        console.log("❌ Error: Insufficient balance!");
    } else {
        console.log("✅ Balance is sufficient.");
    }
}

main().catch(console.error);
