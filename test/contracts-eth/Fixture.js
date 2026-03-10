const {
  // time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

// 导入模块化的配置
const { deployContracts } = require("./fixtures/contracts");
const { createConnectors } = require("./fixtures/connectors");
const { configureTokens } = require("./fixtures/tokenConfig");
const { initializeContracts } = require("./fixtures/initialization");

async function deployTruthBoxFixture() {
  // 1. 部署所有合约
  const { signers, contracts } = await deployContracts();
  
  // 2. 创建合约连接器
  const connectors = await createConnectors(signers, contracts);
  
  // 3. 配置代币（铸造、授权、流动性）
  await configureTokens(signers, contracts, connectors);
  
  // 4. 初始化合约参数和创建测试数据
  const testData = await initializeContracts(contracts, connectors, signers);
  
  // 5. 定义时间常量
  const DAY = 24 * 60 * 60;
  const MONTH = 30 * 24 * 60 * 60;
  const YEAR = 365 * 24 * 60 * 60;

  // 6. 返回所有测试需要的数据和连接器
  return {
    // 签名者
    ...signers,
    DAY, MONTH, YEAR,
    
    // 合约实例
    ...contracts,
    
    // 连接器（保持向后兼容的命名）
    truthBox_minter: connectors.truthBoxConnectors.minter,
    truthBox_other: connectors.truthBoxConnectors.other,
    truthBox_DAO: connectors.truthBoxConnectors.dao,
    truthBox_buyer: connectors.truthBoxConnectors.buyer,
    
    exchange_minter: connectors.exchangeConnectors.minter,
    exchange_buyer: connectors.exchangeConnectors.buyer,
    exchange_buyer2: connectors.exchangeConnectors.buyer2,
    exchange_DAO: connectors.exchangeConnectors.dao,
    exchange_seller: connectors.exchangeConnectors.seller,
    exchange_other: connectors.exchangeConnectors.other,
    exchange_completer: connectors.exchangeConnectors.completer,
    
    fundManager_dao_fund_manager: connectors.fundManagerConnectors.dao_fund_manager,
    fundManager_completer: connectors.fundManagerConnectors.completer,
    fundManager_minter: connectors.fundManagerConnectors.minter,
    fundManager_buyer: connectors.fundManagerConnectors.buyer,
    fundManager_buyer2: connectors.fundManagerConnectors.buyer2,
    fundManager_DAO: connectors.fundManagerConnectors.dao,
    
    swapContract_minter: connectors.swapContractConnectors.minter,
    swapContract_buyer: connectors.swapContractConnectors.buyer,
    swapContract_other: connectors.swapContractConnectors.other,
    
    userManager_buyer: connectors.userManagerConnectors.buyer,
    userManager_buyer2: connectors.userManagerConnectors.buyer2,
    userManager_minter: connectors.userManagerConnectors.minter,
    userManager_seller: connectors.userManagerConnectors.seller,
    userManager_completer: connectors.userManagerConnectors.completer,
    userManager_other: connectors.userManagerConnectors.other,
    userManager_DAO: connectors.userManagerConnectors.dao,
    
    // 测试数据
    ...testData
  };
}

module.exports = {
  // deployFeeTokenFixture,
  deployTruthBoxFixture
};

