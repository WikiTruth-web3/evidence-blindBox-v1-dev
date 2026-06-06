import hre from "hardhat";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { 
  AddressManagerModule, 
  ForwarderModule, 
  UserManagerModule, 
  BlindBoxModule, 
  ExchangeModule, 
  FundManagerModule,
  MockPriceOracleModule
} from "../../ignition/modules/06_deploys";

// ==============
//  npx hardhat run scripts/deploy/deploy_slow_06.ts --network sapphire-testnet
// ==============----------------------------------------------------------------------

// Helper function to delay execution by ms
const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  const networkName = hre.network.name;
  console.log(`[SLOW DEPLOY] Starting slow deployment on network: ${networkName}`);

  // Using a consistent deployment ID per network so Ignition can incremental-deploy and resume upon errors
  const deploymentId = `slow-deploy-${networkName}`;
  console.log(`[SLOW DEPLOY] Session deployment ID: ${deploymentId}`);

  // 1. AddressManager
  console.log("\n[1/7] Deploying AddressManager...");
  const { addressManager } = await hre.ignition.deploy(AddressManagerModule, { deploymentId });
  const addressManagerAddr = await addressManager.getAddress();
  console.log(`AddressManager deployed at: ${addressManagerAddr}`);

  console.log("Waiting 5 seconds before next deployment...");
  await delay(5000);

  // 2. Forwarder
  console.log("\n[2/7] Deploying Forwarder...");
  const { forwarder } = await hre.ignition.deploy(ForwarderModule, { deploymentId });
  const forwarderAddr = await forwarder.getAddress();
  console.log(`Forwarder deployed at: ${forwarderAddr}`);

  console.log("Waiting 5 seconds before next deployment...");
  await delay(5000);

  // 3. UserManager
  console.log("\n[3/7] Deploying UserManager...");
  const { userManager } = await hre.ignition.deploy(UserManagerModule, { deploymentId });
  const userManagerAddr = await userManager.getAddress();
  console.log(`UserManager deployed at: ${userManagerAddr}`);

  console.log("Waiting 5 seconds before next deployment...");
  await delay(5000);

  // 4. BlindBox
  console.log("\n[4/7] Deploying BlindBox...");
  const { blindBox } = await hre.ignition.deploy(BlindBoxModule, { deploymentId });
  const blindBoxAddr = await blindBox.getAddress();
  console.log(`BlindBox deployed at: ${blindBoxAddr}`);

  console.log("Waiting 5 seconds before next deployment...");
  await delay(5000);

  // 5. Exchange
  console.log("\n[5/7] Deploying Exchange...");
  const { exchange } = await hre.ignition.deploy(ExchangeModule, { deploymentId });
  const exchangeAddr = await exchange.getAddress();
  console.log(`Exchange deployed at: ${exchangeAddr}`);

  console.log("Waiting 5 seconds before next deployment...");
  await delay(5000);

  // 6. FundManager
  console.log("\n[6/7] Deploying FundManager...");
  const { fundManager } = await hre.ignition.deploy(FundManagerModule, { deploymentId });
  const fundManagerAddr = await fundManager.getAddress();
  console.log(`FundManager deployed at: ${fundManagerAddr}`);

  console.log("Waiting 5 seconds before next deployment...");
  await delay(5000);

  // 7. MockPriceOracle
  console.log("\n[7/7] Deploying MockPriceOracle...");
  const { mockPriceOracle } = await hre.ignition.deploy(MockPriceOracleModule, { deploymentId });
  const mockPriceOracleAddr = await mockPriceOracle.getAddress();
  console.log(`MockPriceOracle deployed at: ${mockPriceOracleAddr}`);

  // 8. Update deployments JSON
  console.log("\n[+] Updating deployments JSON file...");
  const jsonPath = path.join(__dirname, "../deployments/contracts-testnet.json");
  let deploymentJson: any = { Main: {}, Spread: {} };
  
  if (fs.existsSync(jsonPath)) {
    const rawData = fs.readFileSync(jsonPath, "utf8");
    try {
      deploymentJson = JSON.parse(rawData);
    } catch (e) {
      console.warn("Could not parse existing contracts-testnet.json, recreating empty structure.");
    }
  }

  // Ensure nested Main and Spread sections exist
  if (!deploymentJson.Main) deploymentJson.Main = {};
  if (!deploymentJson.Spread) deploymentJson.Spread = {};

  // Update Main addresses
  deploymentJson.Main.AddressManager = addressManagerAddr;
  deploymentJson.Main.Forwarder = forwarderAddr;
  deploymentJson.Main.UserManager = userManagerAddr;
  deploymentJson.Main.BlindBox = blindBoxAddr;
  deploymentJson.Main.Exchange = exchangeAddr;
  deploymentJson.Main.FundManager = fundManagerAddr;

  // Update Spread addresses
  deploymentJson.Spread.MockPriceOracle = mockPriceOracleAddr;

  fs.writeFileSync(jsonPath, JSON.stringify(deploymentJson, null, 4), "utf8");
  console.log(`Updated JSON configuration at ${jsonPath}`);

  console.log("\n🎉 Complete deployment succeeded!");
  console.log("--------------------------------------------------");
  console.log(`Summary of Deployed Addresses:`);
  console.log(`AddressManager:  ${addressManagerAddr}`);
  console.log(`Forwarder:       ${forwarderAddr}`);
  console.log(`UserManager:     ${userManagerAddr}`);
  console.log(`BlindBox:        ${blindBoxAddr}`);
  console.log(`Exchange:        ${exchangeAddr}`);
  console.log(`FundManager:     ${fundManagerAddr}`);
  console.log(`MockPriceOracle: ${mockPriceOracleAddr}`);
  console.log("--------------------------------------------------");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment process failed:", error);
    process.exit(1);
  });