/**
 * 测试夹具模块索引文件
 * 统一导出所有测试相关的模块
 */

const { deployContracts } = require("./contracts");
const { createConnectors } = require("./connectors");
const { configureTokens } = require("./tokenConfig");
const { 
  initializeContracts, 
  generateTestData, 
  createTestTruthBoxes,
  incrementRate,
  bidIncrementRate,
  serviceFeeRate,
  otherRewardRate,
  slippageProtection
} = require("./initialization");

module.exports = {
  // 合约部署
  deployContracts,
  
  // 连接器创建
  createConnectors,
  
  // 代币配置
  configureTokens,
  
  // 初始化配置
  initializeContracts,
  generateTestData,
  createTestTruthBoxes,
  incrementRate,
  bidIncrementRate,
  serviceFeeRate,
  otherRewardRate,
  slippageProtection,
  
  // 工具函数
  utils: {
    generateTestData,
    createTestTruthBoxes
  }
};
