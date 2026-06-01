/**
 * 合约部署模块
 * 负责部署所有智能合约
 */
const crypto = require('crypto');

async function deployContracts() {
  // 获取多个签名者，通常第一个是部署合约的账户
  const [
    admin, admin2, dao, governance, minter, 
    seller, buyer, buyer2, completer, other, 
    other2, dao_treasury, siweAuth, quoter
  ] = await ethers.getSigners();

  const {
    decimals_settlementToken,
    decimals_wBTC,
    decimals_wETH,
    decimals_wROSE
  } = require("./decimals");

  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const settlementToken = await MockERC20.deploy("Truth Coin Test", "TCT", decimals_settlementToken);
  const wBTC = await MockERC20.deploy("wBTC", "wBTC", decimals_wBTC);
  const wETH = await MockERC20.deploy("WETH for WikiTruth", "WETH", decimals_wETH);
  const wROSE = await MockERC20.deploy("WROSE for WikiTruth", "WROSE", decimals_wROSE);
  // ---
  const randomBytes = crypto.randomBytes(36);
  const pers = '0x' + randomBytes.toString('hex');
  const PrivacyERC20 = await ethers.getContractFactory("PrivacyERC20ETH");
  const settlementToken_Privacy = await PrivacyERC20.deploy(settlementToken, pers);

  const AddressManager = await ethers.getContractFactory("AddressManager");
  const addressManager = await AddressManager.deploy();

  const Forwarder = await ethers.getContractFactory("Forwarder");
  const forwarder = await Forwarder.deploy("Hardhat test forwarder",addressManager.target);

  // ---
  const BlindBox = await ethers.getContractFactory("BlindBox");
  const blindBox = await BlindBox.deploy(addressManager.target, forwarder.target);

  const FundManager = await ethers.getContractFactory("FundManager");
  const fundManager = await FundManager.deploy(addressManager.target,forwarder.target);
  
  const Exchange = await ethers.getContractFactory("Exchange");
  const exchange = await Exchange.deploy(addressManager.target,forwarder.target);

  const UserManager = await ethers.getContractFactory("UserManager");
  const userManager = await UserManager.deploy(addressManager.target);

  const MockPriceOracle = await ethers.getContractFactory("MockPriceOracle");
  const mockPriceOracle = await MockPriceOracle.deploy(addressManager.target);

  return {
    signers: {
      admin, admin2, dao, governance, minter, 
      seller, buyer, buyer2, completer, other, 
      other2, dao_treasury, 
      siweAuth // NOTE: 本地测试，使用地址来替代siweAuth令牌合约地址。
    },
    contracts: {
      addressManager,
      settlementToken,
      settlementToken_Privacy,
      wBTC,
      wETH,
      wROSE,
      blindBox,
      fundManager,
      exchange,
      userManager,
      forwarder,
      mockPriceOracle
    },
  };
}

module.exports = {
  deployContracts
};
