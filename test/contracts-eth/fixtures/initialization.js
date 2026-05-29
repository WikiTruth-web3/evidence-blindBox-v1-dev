/**
 * 初始化配置模块
 * 负责合约的初始参数设置和地址配置
 */

const crypto = require('crypto');

// 设置初始参数,并导出
const incrementRate = 200;
const bidIncrementRate = 110;
const serviceFeeRate = 30;
const helperFeeRate = 10;
const slippageProtection = 10;

async function initializeContracts(contracts, connectors, signers) {
  const {
    addressManager,
    blindBox,
    exchange,
    fundManager,
    mockPriceOracle,
    userManager,
    forwarder,
    settlementToken,
    wBTC,
  } = contracts;

  const {
    blindBoxConnectors,
    exchangeConnectors,
    fundManagerConnectors,
  } = connectors;

  // 从传入的 signers 中获取需要的签名者
  const {
    dao, governance, dao_treasury, siweAuth, quoter
  } = signers;

  const addressList = [
    blindBox.target, 
    exchange.target, 
    fundManager.target, 
    userManager.target,
    // ------------------------- 
    siweAuth.address, // NOTE: 本地测试，使用地址来替代siweAuth令牌合约地址。
    forwarder.target,
    // --------------------------
    dao.address,
    dao_treasury.address,
    governance.address,

  ];


  for (let i = 0; i < addressList.length; i++) {
    await addressManager.setMainContract(i, addressList[i]);
  }

  await blindBox.setContracts();
  await exchange.setContracts();
  await fundManager.setContracts();
  await userManager.setContracts();
  await forwarder.setContracts();
  
  // 注册预言机扩展合约
  await addressManager.setSpreadContract("PriceOracle", mockPriceOracle.target);
  // 设置 1 wBTC = 2 Truth Coin (TCT)
  await mockPriceOracle.setPrice(wBTC.target, settlementToken.target, ethers.parseUnits("2", 18));
  
  // 在tokenConfig中设置
  await addressManager.setSettlementToken(settlementToken.target);
  await addressManager.addToken(wBTC.target);

  // 设置初始参数
  await blindBoxConnectors.dao.setIncrementRate(incrementRate);
  await exchangeConnectors.dao.setRefundRequestPeriod(15 * 24 * 60 * 60); // 15天
  await exchangeConnectors.dao.setArbitrationPeriod(30 * 24 * 60 * 60); // 30天
  await exchangeConnectors.dao.setBidIncrementRate(bidIncrementRate);
  await fundManagerConnectors.dao.setServiceFeeRate(serviceFeeRate);
  await fundManagerConnectors.dao.setHelperFeeRate(helperFeeRate);

  // 生成测试用的随机数据
  const testData = generateTestData();

  // 创建测试用的BlindBox项目
  await createTestBlindBoxes(blindBoxConnectors.minter, testData);

  return testData;
}

function generateTestData() {
  // 生成随机字节数据
  const randomBytes = crypto.randomBytes(32);
  
  return {
    bytes_mint: '0x' + randomBytes.toString('hex'),
    bytes32_1: '0x' + crypto.randomBytes(32).toString('hex'),
    bytes32_2: '0x' + crypto.randomBytes(32).toString('hex'),
    bytes32_3: '0x' + crypto.randomBytes(32).toString('hex'),
    address_zero: '0x0000000000000000000000000000000000000000',
    bytes32_zero: '0x0000000000000000000000000000000000000000000000000000000000000000'
  };
}

async function createTestBlindBoxes(blindBoxMinter, testData) {
  const signers = await ethers.getSigners();
  const minter = signers[4]; // minter 是第5个签名者

  // 创建测试用的BlindBox项目
  await blindBoxMinter.create("00_infoURI", testData.bytes_mint, 1000);
  await blindBoxMinter.create("01_infoURI", testData.bytes_mint, 1000);
  await blindBoxMinter.create("02_infoURI", testData.bytes_mint, 1000);
  await blindBoxMinter.create("03_infoURI", testData.bytes_mint, 1000);
  await blindBoxMinter.create("04_infoURI", testData.bytes_mint, 1000);
  await blindBoxMinter.createAndPublish("05_infoURI——public");
}

module.exports = {
  initializeContracts,
  generateTestData,
  createTestBlindBoxes,
  incrementRate,
  bidIncrementRate,
  serviceFeeRate,
  helperFeeRate,
  slippageProtection
};
