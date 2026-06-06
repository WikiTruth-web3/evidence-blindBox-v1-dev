import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import * as fs from "fs";
import * as path from "path";

// npx hardhat run scripts/deploy/deploy_slow_07.ts --network sapphire-testnet

// Helper to load deployments JSON and get needed addresses
function getCoreAddresses() {
  const jsonPath = path.join(__dirname, "../../deployments/contracts-testnet.json");
  if (!fs.existsSync(jsonPath)) {
    throw new Error(`Critical: contracts-testnet.json not found at ${jsonPath}. Please deploy AddressManager and Forwarder first.`);
  }
  const config = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
  if (!config.Main || !config.Main.AddressManager || !config.Main.Forwarder) {
    throw new Error("AddressManager or Forwarder address is missing from contracts-testnet.json.");
  }
  return {
    addressManager: config.Main.AddressManager,
    forwarder: config.Main.Forwarder
  };
}

// Dedicated module to deploy BlindBox only, using existing AddressManager and Forwarder
export const BlindBoxSelectiveModule = buildModule("BlindBoxSelectiveModule", (m) => {
  const { addressManager, forwarder } = getCoreAddresses();
  const pers = ethers.hexlify(ethers.randomBytes(32));

  const blindBox = m.contract("BlindBox", [
    addressManager,
    forwarder,
    pers
  ], {
    id: "BlindBox"
  });

  return { blindBox };
});

// Dedicated module to deploy Exchange only, using existing AddressManager and Forwarder
export const ExchangeSelectiveModule = buildModule("ExchangeSelectiveModule", (m) => {
  const { addressManager, forwarder } = getCoreAddresses();

  const exchange = m.contract("Exchange", [
    addressManager,
    forwarder
  ], {
    id: "Exchange"
  });

  return { exchange };
});
