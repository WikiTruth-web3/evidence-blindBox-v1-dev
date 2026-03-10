/**
 * 合约连接器模块
 * 负责为不同用户创建合约连接器实例
 */

async function createConnectors(signers, contracts) {

  const {
    admin, admin2, dao, governance, minter, 
    seller, buyer, buyer2, completer, other, 
    other2, dao_fund_manager, forwarder,
    siweAuth, // 替代SiweAuth 合约，因为eth版本不使用SiweAuth
  } = signers;

  const {
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
  } = contracts;

  // TruthBox 连接器
  const truthBoxConnectors = {
    other: truthBox.connect(other),
    minter: truthBox.connect(minter),
    dao: truthBox.connect(dao),
    buyer: truthBox.connect(buyer),
    buyer2: truthBox.connect(buyer2),
  };

  // Exchange 连接器
  const exchangeConnectors = {
    minter: exchange.connect(minter),
    dao: exchange.connect(dao),
    seller: exchange.connect(seller),
    buyer: exchange.connect(buyer),
    buyer2: exchange.connect(buyer2),
    completer: exchange.connect(completer),
    other: exchange.connect(other)
  };

  // UserManager 连接器
  const userManagerConnectors = {
    dao: userManager.connect(dao),
    minter: userManager.connect(minter),
    buyer: userManager.connect(buyer),
    buyer2: userManager.connect(buyer2),
    seller: userManager.connect(seller),
    completer: userManager.connect(completer),
    other: userManager.connect(other),
  };

  // FundManager 连接器
  const fundManagerConnectors = {
    minter: fundManager.connect(minter),
    buyer: fundManager.connect(buyer),
    buyer2: fundManager.connect(buyer2),
    dao: fundManager.connect(dao),
    dao_fund_manager: fundManager.connect(dao_fund_manager),
    completer: fundManager.connect(completer)
  };

  // 代币连接器
  const tokenConnectors = {
    settlementToken: {
      buyer: settlementToken.connect(buyer),
      buyer2: settlementToken.connect(buyer2),
      other: settlementToken.connect(other),
      other2: settlementToken.connect(other2),
      minter: settlementToken.connect(minter),
      seller:settlementToken.connect(seller),
      completer:settlementToken.connect(completer),
    },
    wBTC: {
      minter: wBTC.connect(minter),
      buyer: wBTC.connect(buyer),
      buyer2: wBTC.connect(buyer2),
      other: wBTC.connect(other)
    }
  };

  // SwapContract 连接器
  const swapContractConnectors = {
    minter: swapContract.connect(minter),
    buyer: swapContract.connect(buyer),
    other: swapContract.connect(other)
  };

  return {
    truthBoxConnectors,
    exchangeConnectors,
    userManagerConnectors,
    fundManagerConnectors,
    tokenConnectors,
    swapContractConnectors
  };
}

module.exports = {
  createConnectors
};
