import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { wikiTruth_contracts_address } from "../../scripts/utils/contracts_address";

// 1. deploy: npx hardhat ignition deploy ignition/modules/deploys.ts --network sapphire-testnet

export default buildModule("Deploy_20260213", (m) => {
  const addressManager_Proxy = wikiTruth_contracts_address.addressManager;

  // const exchange = m.contract("Exchange", [addressManager_Proxy]);
  const truthBox = m.contract("TruthBox", [addressManager_Proxy]);
  // const truthNFT = m.contract("TruthNFT", [addressManager_Proxy]);
  // const fundManager = m.contract("FundManager", [addressManager_Proxy]);
  // const userId = m.contract("UserId", [addressManager_Proxy]);
  
  return { 
    // exchange, 
    truthBox,
    // fundManager,
    // truthNFT, 
    // userId 
  };
});
