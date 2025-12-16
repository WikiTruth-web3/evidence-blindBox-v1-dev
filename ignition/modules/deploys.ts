import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { wikiTruth_contracts_address } from "../../scripts/utils/wikiTruth_contracts_address";

export default buildModule("Deploy_20251213", (m) => {
  const addressManagerProxy = wikiTruth_contracts_address.addressManager;

  const exchange = m.contract("Exchange", [addressManagerProxy]);
  // const truthBox = m.contract("TruthBox", [addressManagerProxy]);
  // const userId = m.contract("UserId", [addressManagerProxy]);
  
  return { 
    exchange, 
    // truthBox, 
    // userId 
  };
});

// 1. 部署命令：npx hardhat ignition deploy ignition/modules/deploys.ts --network sapphire-testnet
// 2. 合约地址: 