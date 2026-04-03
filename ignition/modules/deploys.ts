import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { core_contracts_address } from "../../scripts/utils/contracts_address";
import { ethers } from "ethers";


// 1. deploy: npx hardhat ignition deploy ignition/modules/deploys.ts --network sapphire-testnet

export default buildModule("Deploy_20260403", (m) => {
  const addressManager = core_contracts_address.addressManager;
  const forwarder = core_contracts_address.forwarder;
  const pers = ethers.hexlify(ethers.randomBytes(32));

  // const exchange = m.contract("Exchange", [addressManager_Proxy]);
  const truthBox = m.contract("TruthBox", [addressManager,forwarder,pers]);
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
