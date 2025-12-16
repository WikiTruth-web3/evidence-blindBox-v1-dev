import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * 模块化的代理部署方案
 * 可以分别导入和组合使用
 */

// ==================== 模块1：AddressManager ====================
// export const AddressManagerModule = buildModule("AddressManagerModule", (m) => {
//   const implementation = m.contract("AddressManager", [], {
//     id: "AddressManager_Implementation"
//   });

//   const proxy = m.contract("Proxy_WikiTruth", [implementation], {
//     id: "AddressManager_Proxy"
//   });

//   return { implementation, proxy };
// });

// ==================== 模块2：TruthBox ====================
export const TruthBoxModule = buildModule("TruthBoxModule", (m) => {
  // const { proxy: addressManagerProxy } = m.useModule(AddressManagerModule);

  // const implementation = m.contract("TruthBox", [addressManagerProxy], {
  //   id: "TruthBox_Implementation"
  // });
//   "TruthBoxModule#TruthBox_Implementation": "0x4058F87ac5703c4929D43901FAA464bC139bB9D5",

  const implementation = "0x4058F87ac5703c4929D43901FAA464bC139bB9D5"

  const proxy = m.contract("Proxy_WikiTruth", [implementation], {
    id: "TruthBox_Proxy"
  });

  return {  
    // implementation,
    proxy };
});

// ==================== 模块3：TruthNFT ====================
export const TruthNFTModule = buildModule("TruthNFTModule", (m) => {
  // const { proxy: addressManagerProxy } = m.useModule(AddressManagerModule);

  // const implementation = m.contract("TruthNFT", [addressManagerProxy], {
  //   id: "TruthNFT_Implementation"
  // });
//   "TruthNFTModule#TruthNFT_Implementation": "0xa67C79a3016CCd8522B51e90aE7C0AaD39748E62",

  const implementation = "0xa67C79a3016CCd8522B51e90aE7C0AaD39748E62"

  const proxy = m.contract("Proxy_WikiTruth", [implementation], {
    id: "TruthNFT_Proxy"
  });

  return { 
    // implementation,
    proxy };
});

// ==================== 模块4：Exchange ====================
export const ExchangeModule = buildModule("ExchangeModule", (m) => {
  // const { proxy: addressManagerProxy } = m.useModule(AddressManagerModule);

  // const implementation = m.contract("Exchange", [addressManagerProxy], {
  //   id: "Exchange_Implementation"
  // });
//   "ExchangeModule#Exchange_Implementation": "0xf963A9afD6F4463D662B56D8A0fa304d68Dcc403",

  const implementation = "0xf963A9afD6F4463D662B56D8A0fa304d68Dcc403"

  const proxy = m.contract("Proxy_WikiTruth", [implementation], {
    id: "Exchange_Proxy"
  });

  return { 
    // implementation,
    proxy };
});

// ==================== 模块5：FundManager ====================
export const FundManagerModule = buildModule("FundManagerModule", (m) => {
  // const { proxy: addressManagerProxy } = m.useModule(AddressManagerModule);

  // const implementation = m.contract("FundManager", [addressManagerProxy], {
  //   id: "FundManager_Implementation"
  // });
//   "FundManagerModule#FundManager_Implementation": "0x69CAe2422Cb8CF00663Bf1C53869e1340b19B272",

  const implementation = "0x69CAe2422Cb8CF00663Bf1C53869e1340b19B272"

  const proxy = m.contract("Proxy_WikiTruth", [implementation], {
    id: "FundManager_Proxy"
  });

  return { 
    // implementation,
    proxy };
});

// ==================== 模块6：UserId ====================
export const UserIdModule = buildModule("UserIdModule", (m) => {
  // const { proxy: addressManagerProxy } = m.useModule(AddressManagerModule);

  // const implementation = m.contract("UserId", [addressManagerProxy], {
  //   id: "UserId_Implementation"
  // });
//   "UserIdModule#UserId_Implementation": "0x828230Dfcb432A778f1f48e2C2DdC12353f58BE1"

  const implementation = "0x828230Dfcb432A778f1f48e2C2DdC12353f58BE1"

  const proxy = m.contract("Proxy_WikiTruth", [implementation], {
    id: "UserId_Proxy"
  });

  return {  
    // implementation,
    proxy };
});

// ==================== 模块7：SiweAuth ====================
// 没有代理
// export const SiweAuthModule = buildModule("SiweAuthModule", (m) => {
//   const { proxy: addressManagerProxy } = m.useModule(AddressManagerModule);
//   const primaryDomain = 'wikitruth.eth.limo'
//   const domains = ['truthwiki.eth.limo']
//   const implementation = m.contract("SiweAuthWikiTruth", [
//     addressManagerProxy,
//     primaryDomain,
//     domains
//   ], {
//     id: "SiweAuth_Implementation"
//   });

//   return { implementation};
// });

// ==================== 主模块：组合所有模块 ====================
export default buildModule("AllContractsWithProxy", (m) => {
  // const addressManager = m.useModule(AddressManagerModule);
  const truthBox = m.useModule(TruthBoxModule);
  const truthNFT = m.useModule(TruthNFTModule);
  const exchange = m.useModule(ExchangeModule);
  const fundManager = m.useModule(FundManagerModule);
  const userId = m.useModule(UserIdModule);
  // const siweAuthWikiTruth = m.useModule(SiweAuthModule);

  return {
    // addressManagerProxy: addressManager.proxy,
    truthBoxProxy: truthBox.proxy,
    truthNFTProxy: truthNFT.proxy,
    exchangeProxy: exchange.proxy,
    fundManagerProxy: fundManager.proxy,
    userIdProxy: userId.proxy,
    // siweAuth: siweAuthWikiTruth.implementation
  };
});

/**
 * 使用方式：
 * 
 * 1. 部署所有合约：
 * npx hardhat ignition deploy ignition/modules/00_DeployWithProxy_Modular.ts --network sapphire-testnet
 * 
 * 2. 只部署 AddressManager：
 * import { AddressManagerModule } from './00_DeployWithProxy_Modular';
 * npx hardhat ignition deploy ... --module-id AddressManagerModule
 * 
 * 3. 在其他模块中导入使用：
 * import { TruthBoxModule } from './00_DeployWithProxy_Modular';
 */


