import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * 完整的代理部署模块
 * 为每个核心合约部署实现合约和对应的代理合约
 */
export default buildModule("DeployWithProxy", (m) => {

  // ==================== 第一步：部署 AddressManager ====================
  // const addressManagerImpl = m.contract("AddressManager", [], {
  //   id: "AddressManager_Implementation_20251121"
  // });

  const addressManagerImpl = "0x1161f81402206244B1287667e38Fa5fb3C3Ba2bf"

  const addressManagerProxy = "0xd1576960886df1e0b58792b1f1c37CB477734158"
  // const addressManagerProxy = m.contract("Proxy_WikiTruth", [
  //     addressManagerImpl
  //   ], {
  //     id: "AddressManager_Proxy_20251121"
  //   });

  // ==================== 第二步：部署核心合约的实现 ====================
  const truthBoxImpl = '0x4CA6D35678001B0E9B07b1f859d1b2DCDeeefb64'
  //   const truthBoxImpl = m.contract("TruthBox", [
  //   addressManagerProxy
  // ], {
  //   id: "TruthBox_Implementation_20251121"
  // });

  // 按顺序部署实现合约
  const truthNFTImpl = m.contract("TruthNFT", [
    addressManagerProxy
  ], {
    id: "TruthNFT_Implementation_20251121",
  });

  // const exchangeImpl = "0xD58100D1189a30308bDB3fCEad824EA211e7AE2d"
  //   const exchangeImpl = m.contract("Exchange", [
  //   addressManagerProxy
  // ], {
  //   id: "Exchange_Implementation_20251121"
  // }); 

  const fundManagerImpl = "0x67560EbAc7F084571693403725d60977810699bB"
  //   const fundManagerImpl = m.contract("FundManager", [
  //   addressManagerProxy
  // ], {
  //   id: "FundManager_Implementation_20251121"
  // });

  const userIdImpl = m.contract("UserId", [
    addressManagerProxy
  ], {
    id: "UserId_Implementation_20251121",
    after: [truthNFTImpl] // UserId 在 TruthNFT 之后部署
  });

  // const primaryDomain = 'wikitruth.eth.limo'
  // const domains = ['truthwiki.eth.limo']

  // const siweAuthImpl = m.contract("SiweAuthWikiTruth", [
  //   primaryDomain,
  //   domains
  // ], {
  //   id: "SiweAuth_20251015"
  // });

  // ==================== 第三步：为每个实现部署对应的代理 ====================
  // 代理部署依赖于实现合约，并且按顺序执行
  const truthBoxProxy = m.contract("Proxy_WikiTruth", [
    truthBoxImpl
  ], {
    id: "TruthBox_Proxy",
    after: [userIdImpl] // 等待所有实现合约完成
  });

  const truthNFTProxy = m.contract("Proxy_WikiTruth", [
    truthNFTImpl
  ], {
    id: "TruthNFT_Proxy",
    after: [truthBoxProxy] // 按顺序部署代理
  });

  // const exchangeProxy = m.contract("Proxy_WikiTruth", [
  //   exchangeImpl
  // ], {
  //   id: "Exchange_Proxy",
  //   after: [truthNFTProxy]
  // });

  const fundManagerProxy = m.contract("Proxy_WikiTruth", [
    fundManagerImpl
  ], {
    id: "FundManager_Proxy",
    after: [truthBoxProxy]
  });

  const userIdProxy = m.contract("Proxy_WikiTruth", [
    userIdImpl
  ], {
    id: "UserId_Proxy",
    after: [fundManagerProxy] // 最后部署
  });

  // ==================== 返回所有合约 ====================
  return {
    // addressManager: addressManagerImpl,
    // truthBox: truthBoxImpl,
    truthNFT: truthNFTImpl,
    // exchange: exchangeImpl,
    // fundManager: fundManagerImpl,
    userId: userIdImpl,
    // siweAuthWikiTruth: siweAuthImpl,

    // addressManagerProxy: addressManagerProxy,
    truthBoxProxy: truthBoxProxy,
    truthNFTProxy: truthNFTProxy,
    // exchangeProxy: exchangeProxy,
    fundManagerProxy: fundManagerProxy,
    userIdProxy: userIdProxy
    
  };
});

/**
 * 部署命令：
 * npx hardhat ignition deploy ignition/modules/00_DeployWithProxy.ts --network sapphire-testnet
 * 
 * 部署后会在 ignition/deployments/[network]/ 目录下生成：
 * - deployed_addresses.json  包含所有部署的合约地址
 * - journal.jsonl           部署过程记录
 */


