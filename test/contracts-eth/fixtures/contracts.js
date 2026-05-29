/**
 * 合约部署模块
 * 负责部署所有智能合约
 */

async function deployContracts() {
  // 获取多个签名者，通常第一个是部署合约的账户
  const [
    admin, admin2, dao, governance, minter, 
    seller, buyer, buyer2, completer, other, 
    other2, dao_treasury, siweAuth, quoter
  ] = await ethers.getSigners();

  const SettlementToken = await ethers.getContractFactory("MockERC20");
  const settlementToken = await SettlementToken.deploy("Truth Coin Test", "TCT");
  
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const wBTC = await MockERC20.deploy("wBTC", "wBTC");
  const wETH = await MockERC20.deploy("WETH for WikiTruth", "WETH");
  const wROSE = await MockERC20.deploy("WROSE for WikiTruth", "WROSE");

  const SwapContract = await ethers.getContractFactory("SwapContract");
  const swapContract = await SwapContract.deploy();

  // ---

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


  return {
    signers: {
      admin, admin2, dao, governance, minter, 
      seller, buyer, buyer2, completer, other, 
      other2, dao_treasury, 
      siweAuth, // NOTE: 本地测试，使用地址来替代siweAuth令牌合约地址。
      quoter
    },
    contracts: {
      addressManager,
      settlementToken,
      wBTC,
      wETH,
      wROSE,
      blindBox,
      swapContract,
      fundManager,
      exchange,
      userManager,
      forwarder
    }
  };
}

module.exports = {
  deployContracts
};
