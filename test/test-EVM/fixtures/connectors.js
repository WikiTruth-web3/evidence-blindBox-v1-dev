/**
 * 合约连接器模块
 * 负责为不同用户创建合约连接器实例
 */

async function createConnectors(signers, contracts) {
  const {
    admin, admin2, dao, governance, minter, 
    seller, buyer, buyer2, completer, other, 
    other2, dao_fund_manager, siweAuth
  } = signers;

  const {
    addressManager,
    officialToken,
    testToken,
    otherToken,
    otherToken2,
    truthNFT,
    truthBox,
    swapContract,
    fundManager,
    exchange,
    userId
  } = contracts;

  // TruthBox 连接器
  const truthBoxConnectors = {
    other: truthBox.connect(other),
    minter: truthBox.connect(minter),
    dao: truthBox.connect(dao),
    buyer: truthBox.connect(buyer)
  };

  // TruthNFT 连接器
  const truthNFTConnectors = {
    minter: truthNFT.connect(minter),
    other: truthNFT.connect(other),
    buyer: truthNFT.connect(buyer),
    dao: truthNFT.connect(dao)
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

  // UserId 连接器
  const userIdConnectors = {
    buyer: userId.connect(buyer),
    minter: userId.connect(minter),
    dao: userId.connect(dao)
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
    officialToken: {
      buyer: officialToken.connect(buyer),
      buyer2: officialToken.connect(buyer2),
      other: officialToken.connect(other),
      other2: officialToken.connect(other2),
      minter: officialToken.connect(minter)
    },
    testToken: {
      minter: testToken.connect(minter),
      buyer: testToken.connect(buyer),
      buyer2: testToken.connect(buyer2),
      other: testToken.connect(other)
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
    truthNFTConnectors,
    exchangeConnectors,
    userIdConnectors,
    fundManagerConnectors,
    tokenConnectors,
    swapContractConnectors
  };
}

module.exports = {
  createConnectors
};
