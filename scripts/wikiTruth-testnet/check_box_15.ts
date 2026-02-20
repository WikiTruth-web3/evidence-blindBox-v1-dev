import { ethers } from "hardhat";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";

async function main() {
    const truthBoxAddress = wikiTruth_contracts_address.truthBox;
    const truthBox = await ethers.getContractAt("TruthBox", truthBoxAddress);
    
    const boxId = 15;
    const [status, price, deadline] = await truthBox.getBasicData(boxId);
    const blockTime = (await ethers.provider.getBlock("latest"))!.timestamp;

    console.log("--- Box 15 Status ---");
    console.log("Stored Status:", status.toString()); 
    console.log("Price:", ethers.formatEther(price), "WIKITRUTH");
    console.log("Deadline:", new Date(Number(deadline) * 1000).toLocaleString());
    console.log("Current Time:", new Date(Number(blockTime) * 1000).toLocaleString());
    console.log("Deadline (unix):", deadline.toString());
    console.log("BlockTime (unix):", blockTime.toString());
    
    if (deadline < blockTime) {
        console.log("❌ Error: Deadline has already passed!");
    } else if (deadline > BigInt(blockTime) + BigInt(3 * 24 * 3600)) {
        console.log("❌ Error: Deadline is too far in the future (more than 3 days)!");
    } else {
        console.log("✅ Deadline is within the valid range for delaying.");
    }
}

main().catch(console.error);
