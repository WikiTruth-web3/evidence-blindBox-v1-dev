import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";

/**
 * WikiTruth Direct Deployment Module (Non-Proxy)
 * 
 * npx hardhat ignition deploy ignition/modules/06_deploys.ts --network sapphire-testnet
 */

// ==================== Module 1: AddressManager ====================
export const AddressManagerModule = buildModule("AddressManagerModule", (m) => {
  const addressManager = m.contract("AddressManager", [], {
    id: "AddressManager"
  });

  return { addressManager };
});

// ==================== Module 2: Forwarder ====================
export const ForwarderModule = buildModule("ForwarderModule", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);
  
  const forwarder = m.contract("Forwarder", [
    "WikiTruthForwarder",
    addressManager
  ], {
    id: "Forwarder"
  });

  return { forwarder };
});

// ==================== Module 3: SiweAuth ====================
// export const SiweAuthModule = buildModule("SiweAuthModule", (m) => {
//   const primaryDomain = "wikitruth.eth.limo";
//   const domains = ["truthwiki.eth.limo"];

//   const siweAuth = m.contract("SiweAuthWikiTruth", [
//     primaryDomain,
//     domains
//   ], {
//     id: "SiweAuth"
//   });

//   return { siweAuth };
// });

// ==================== Module 4: UserManager ====================
export const UserManagerModule = buildModule("UserManagerModule", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);
  // 引入前置模块，强制部署顺序，避免并行部署导致 nonce 冲突或被 RPC 节点拦截
  const { forwarder } = m.useModule(ForwarderModule);
  
  // Custom personalization bytes for Sapphire KDF
  const pers = ethers.hexlify(ethers.randomBytes(32));

  const userManager = m.contract("UserManager", [
    addressManager,
    pers
  ], {
    id: "UserManager",
    after: [forwarder] // 强制在 Forwarder 部署完成后再执行
  });

  return { userManager };
});

// ==================== Module 5: TruthBox ====================
export const TruthBoxModule = buildModule("TruthBoxModule", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);
  const { forwarder } = m.useModule(ForwarderModule);
  const { userManager } = m.useModule(UserManagerModule);

  const pers = ethers.hexlify(ethers.randomBytes(32));

  const truthBox = m.contract("TruthBox", [
    addressManager,
    forwarder,
    pers
  ], {
    id: "TruthBox",
    after: [userManager] // 强制在 UserManager 部署完成后再执行
  });

  return { truthBox };
});

// ==================== Module 6: Exchange ====================
export const ExchangeModule = buildModule("ExchangeModule", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);
  const { forwarder } = m.useModule(ForwarderModule);
  const { truthBox } = m.useModule(TruthBoxModule);

  const exchange = m.contract("Exchange", [
    addressManager,
    forwarder
  ], {
    id: "Exchange",
    after: [truthBox] // 强制在 TruthBox 部署完成后再执行
  });

  return { exchange };
});

// ==================== Module 7: FundManager ====================
export const FundManagerModule = buildModule("FundManagerModule", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);
  const { forwarder } = m.useModule(ForwarderModule);
  const { exchange } = m.useModule(ExchangeModule);

  const fundManager = m.contract("FundManager", [
    addressManager,
    forwarder
  ], {
    id: "FundManager",
    after: [exchange] // 强制在 Exchange 部署完成后再执行
  });

  return { fundManager };
});

// ==================== Main Module: Coordination ====================
export default buildModule("WikiTruthDirectDeploy", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);

  const { forwarder } = m.useModule(ForwarderModule);
  // const { siweAuth } = m.useModule(SiweAuthModule);
  const { userManager } = m.useModule(UserManagerModule);
  const { truthBox } = m.useModule(TruthBoxModule);
  const { exchange } = m.useModule(ExchangeModule);
  const { fundManager } = m.useModule(FundManagerModule);

  return {
    addressManager,
    forwarder,
    // siweAuth,
    userManager,
    truthBox,
    exchange,
    fundManager
  };
});



