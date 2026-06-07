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
  // 'BlindBox',
  // 'Exchange',
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

// Mapping config for contracts to deploy
const contractConfigs: Record<string, {
  module: any;
  futureId: string;
  resultKey: string;
}> = {
  BlindBox: {
    module: BlindBoxSelectiveModule,
    futureId: "BlindBoxSelectiveModule#BlindBox",
    resultKey: "blindBox",
  },
  Exchange: {
    module: ExchangeSelectiveModule,
    futureId: "ExchangeSelectiveModule#Exchange",
    resultKey: "exchange",
  },
  FundManager: {
    module: FundManagerSelectiveModule,
    futureId: "FundManagerSelectiveModule#FundManager",
    resultKey: "fundManager",
  }
};

async function main() {
  const networkName = hre.network.name;
  console.log(`[SELECTIVE DEPLOY] Starting selective slow deployment on network: ${networkName}`);

  // Using a clean dedicated session ID to isolate from old deployment history
  const deploymentId = `selective-deploy-${networkName}`;
  console.log(`[SELECTIVE DEPLOY] Session deployment ID: ${deploymentId}`);

  const jsonPath = path.join(__dirname, "../../deployments/contracts-testnet.json");
  let deploymentJson = loadConfigJson(jsonPath);

  const deployedAddresses: Record<string, string> = {};

  for (let i = 0; i < deployList.length; i++) {
    const contractName = deployList[i];
    const config = contractConfigs[contractName];
    if (!config) {
      console.warn(`[SELECTIVE DEPLOY] Warning: Unknown contract "${contractName}" in deployList. Skipping.`);
      continue;
    }

    console.log(`\n[${i + 1}/${deployList.length}] Processing deployment for: ${contractName}...`);

    try {
      console.log(`Wiping previous Selective state for ${config.futureId}...`);
      await hre.run("ignition:wipe", {
        deploymentId,
        futureId: config.futureId,
      });
      console.log("Wipe completed successfully.");
    } catch (e) {
      console.log(`No existing selective record found to wipe for ${contractName}, proceeding.`);
    }

    console.log(`Deploying ${contractName}...`);
    const deployResult = await hre.ignition.deploy(config.module, { deploymentId });
    const contractInstance = (deployResult as any)[config.resultKey];
    if (!contractInstance) {
      throw new Error(`Deployment result did not return contract with key: ${config.resultKey}`);
    }
    const contractAddr = await contractInstance.getAddress();
    console.log(`${contractName} deployed at: ${contractAddr}`);

    // Update Main config immediately
    if (!deploymentJson.Main) deploymentJson.Main = {};
    deploymentJson.Main[contractName] = contractAddr;
    fs.writeFileSync(jsonPath, JSON.stringify(deploymentJson, null, 4), "utf8");
    console.log(`Updated ${contractName} address in contracts-testnet.json`);

    deployedAddresses[contractName] = contractAddr;

    // Wait 5 seconds before next deployment if not the last one
    if (i < deployList.length - 1) {
      console.log("Waiting 5 seconds before next deployment...");
      await delay(5000);
    }
  }

  console.log("\n🎉 Selective deployment succeeded!");
  console.log("--------------------------------------------------");
  console.log(`Summary of Deployed Addresses:`);
  for (const [name, addr] of Object.entries(deployedAddresses)) {
    console.log(`${name}: ${addr}`);
  }
  console.log("--------------------------------------------------");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment process failed:", error);
    process.exit(1);
  });
