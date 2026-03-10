/**
 * 合约部署模块
 * 负责部署所有智能合约
 */

async function deployContracts() {
  // 获取多个签名者，通常第一个是部署合约的账户
  const [
    admin, admin2, dao, governance, minter, 
    seller, buyer, buyer2, completer, other, 
    other2, dao_fund_manager, siweAuth, quoter, forwarder
  ] = await ethers.getSigners();

  // 部署核心管理合约
  const AddressManager = await ethers.getContractFactory("AddressManager");
  const addressManager = await AddressManager.deploy();

  // 部署代币合约
  const SettlementToken = await ethers.getContractFactory("MockERC20");
  const settlementToken = await SettlementToken.deploy("Truth Coin Test", "TCT");
  
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const wBTC = await MockERC20.deploy("wBTC", "wBTC");
  const wETH = await MockERC20.deploy("WETH for WikiTruth", "WETH");
  const wROSE = await MockERC20.deploy("WROSE for WikiTruth", "WROSE");

  const TruthBox = await ethers.getContractFactory("TruthBox");
  const truthBox = await TruthBox.deploy(addressManager.target);

  // 部署交换和资金管理合约
  const SwapContract = await ethers.getContractFactory("SwapContract");
  const swapContract = await SwapContract.deploy();

  const FundManager = await ethers.getContractFactory("FundManager");
  const fundManager = await FundManager.deploy(addressManager.target);
  
  const Exchange = await ethers.getContractFactory("Exchange");
  const exchange = await Exchange.deploy(addressManager.target);

  const UserManager = await ethers.getContractFactory("UserManager");
  const userManager = await UserManager.deploy(addressManager.target);

  return {
    signers: {
      admin, admin2, dao, governance, minter, 
      seller, buyer, buyer2, completer, other, 
      other2, dao_fund_manager, 
      siweAuth, // NOTE: 本地测试，使用地址来替代siweAuth令牌合约地址。
      quoter, 
      forwarder
    },
    contracts: {
      addressManager,
      settlementToken,
      wBTC,
      wETH,
      wROSE,
      truthBox,
      swapContract,
      fundManager,
      exchange,
      userManager
    }
  };
}

module.exports = {
  deployContracts
};
