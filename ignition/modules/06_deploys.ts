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

// ==================== Module 5: BlindBox ====================
export const BlindBoxModule = buildModule("BlindBoxModule", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);
  const { forwarder } = m.useModule(ForwarderModule);
  const { userManager } = m.useModule(UserManagerModule);

  const pers = ethers.hexlify(ethers.randomBytes(32));

  const blindBox = m.contract("BlindBox", [
    addressManager,
    forwarder,
    pers
  ], {
    id: "BlindBox",
    after: [userManager] // 强制在 UserManager 部署完成后再执行
  });

  return { blindBox };
});

// ==================== Module 6: Exchange ====================
export const ExchangeModule = buildModule("ExchangeModule", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);
  const { forwarder } = m.useModule(ForwarderModule);
  const { blindBox } = m.useModule(BlindBoxModule);

  const exchange = m.contract("Exchange", [
    addressManager,
    forwarder
  ], {
    id: "Exchange",
    after: [blindBox] // 强制在 BlindBox 部署完成后再执行
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

// ==================== Module 8: MockPriceOracle ====================
export const MockPriceOracleModule = buildModule("MockPriceOracleModule", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);
  const { fundManager } = m.useModule(FundManagerModule);

  const mockPriceOracle = m.contract("MockPriceOracle", [], {
    id: "MockPriceOracle",
    after: [fundManager] // 强制在 FundManager 部署完成后再执行
  });

  return { mockPriceOracle };
});

// ==================== Main Module: Coordination ====================
export default buildModule("WikiTruthDirectDeploy", (m) => {
  const { addressManager } = m.useModule(AddressManagerModule);

  const { forwarder } = m.useModule(ForwarderModule);
  // const { siweAuth } = m.useModule(SiweAuthModule);
  const { userManager } = m.useModule(UserManagerModule);
  const { blindBox } = m.useModule(BlindBoxModule);
  const { exchange } = m.useModule(ExchangeModule);
  const { fundManager } = m.useModule(FundManagerModule);
  const { mockPriceOracle } = m.useModule(MockPriceOracleModule);

  return {
    addressManager,
    forwarder,
    // siweAuth,
    userManager,
    blindBox,
    exchange,
    fundManager,
    mockPriceOracle
  };
});




