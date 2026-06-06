import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import main_contracts_address from "../../deployments/contracts-testnet.json"
import { ethers } from "ethers";


// 1. npx hardhat ignition deploy ignition/modules/deploys.ts --network sapphire-testnet
// 2. npx hardhat ignition deploy ignition/modules/deploys.ts --network sapphire-testnet --deployment-id Deploy_20260424_v2_nonce286
export default buildModule("Deploy_20260424_v2", (m) => {
  const addressManager = main_contracts_address.Main.AddressManager;
  const forwarder = main_contracts_address.Main.Forwarder;
  const pers = ethers.hexlify(ethers.randomBytes(32));

  const addressManager_new = m.contract("AddressManager", []);
  const exchange = m.contract("Exchange", [addressManager,forwarder]);
  // const blindBox = m.contract("BlindBox", [addressManager,forwarder,pers]);
  // const truthNFT = m.contract("TruthNFT", [addressManager_Proxy]);
  // const fundManager = m.contract("FundManager", [addressManager_Proxy]);
  // const userId = m.contract("UserId", [addressManager_Proxy]);
  
  return { 
    addressManager_new,
    exchange, 
    // blindBox,
    // fundManager,
    // truthNFT, 
    // userId 
  };
});

/**
 * Deploy_20260424_v2#AddressManager - 0x268863DAeaAdcB45aBb010402600Dea7C0a04744
Deploy_20260424_v2#Exchange - 0x0499bd1974FF382A49D0008b413422518E71e06d
 */