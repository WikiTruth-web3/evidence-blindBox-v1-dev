import hre from "hardhat";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { 
  BlindBoxSelectiveModule, 
  ExchangeSelectiveModule,
  FundManagerSelectiveModule,
} from "../../ignition/modules/07_selective_deploy";

// npx hardhat run scripts/deploy/deploy_slow_07.ts --network sapphire-testnet

const deployList = [
  'BlindBox',
  'Exchange',
  'FundManager'
]
// Helper function to delay execution by ms
const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// Helper to load config JSON safely
function loadConfigJson(jsonPath: string): any {
  if (fs.existsSync(jsonPath)) {
    try {
      return JSON.parse(fs.readFileSync(jsonPath, "utf8"));
    } catch (e) {}
  }
  return { Main: {}, Spread: {} };
}

async function main() {
  const networkName = hre.network.name;
  console.log(`[SELECTIVE DEPLOY] Starting selective slow deployment on network: ${networkName}`);

  // Using a clean dedicated session ID to isolate from old deployment history
  const deploymentId = `selective-deploy-${networkName}`;
  console.log(`[SELECTIVE DEPLOY] Session deployment ID: ${deploymentId}`);

  const jsonPath = path.join(__dirname, "../../deployments/contracts-testnet.json");
  let deploymentJson = loadConfigJson(jsonPath);

  // 1. Deploy BlindBox
  console.log("\n[1/2] Processing deployment for: BlindBox...");
  try {
    console.log("Wiping previous Selective state for BlindBoxSelectiveModule#BlindBox...");
    await hre.run("ignition:wipe", {
      deploymentId,
      futureId: "BlindBoxSelectiveModule#BlindBox",
    });
    console.log("Wipe completed successfully.");
  } catch (e) {
    console.log("No existing selective record found to wipe for BlindBox, proceeding.");
  }

  console.log("Deploying BlindBox...");
  const { blindBox } = await hre.ignition.deploy(BlindBoxSelectiveModule, { deploymentId });
  const blindBoxAddr = await blindBox.getAddress();
  console.log(`BlindBox deployed at: ${blindBoxAddr}`);

  // Update Main config immediately
  if (!deploymentJson.Main) deploymentJson.Main = {};
  deploymentJson.Main.BlindBox = blindBoxAddr;
  fs.writeFileSync(jsonPath, JSON.stringify(deploymentJson, null, 4), "utf8");
  console.log("Updated BlindBox address in contracts-testnet.json");

  console.log("Waiting 5 seconds before next deployment...");
  await delay(5000);

  // 2. Deploy Exchange
  console.log("\n[2/2] Processing deployment for: Exchange...");
  try {
    console.log("Wiping previous Selective state for ExchangeSelectiveModule#Exchange...");
    await hre.run("ignition:wipe", {
      deploymentId,
      futureId: "ExchangeSelectiveModule#Exchange",
    });
    console.log("Wipe completed successfully.");
  } catch (e) {
    console.log("No existing selective record found to wipe for Exchange, proceeding.");
  }

  console.log("Deploying Exchange...");
  const { exchange } = await hre.ignition.deploy(ExchangeSelectiveModule, { deploymentId });
  const exchangeAddr = await exchange.getAddress();
  console.log(`Exchange deployed at: ${exchangeAddr}`);

  // Update Main config immediately
  if (!deploymentJson.Main) deploymentJson.Main = {};
  deploymentJson.Main.Exchange = exchangeAddr;
  fs.writeFileSync(jsonPath, JSON.stringify(deploymentJson, null, 4), "utf8");
  console.log("Updated Exchange address in contracts-testnet.json");

  console.log("\n🎉 Selective deployment succeeded!");
  console.log("--------------------------------------------------");
  console.log(`Summary of Deployed Addresses:`);
  console.log(`BlindBox: ${blindBoxAddr}`);
  console.log(`Exchange: ${exchangeAddr}`);
  console.log("--------------------------------------------------");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment process failed:", error);
    process.exit(1);
  });
