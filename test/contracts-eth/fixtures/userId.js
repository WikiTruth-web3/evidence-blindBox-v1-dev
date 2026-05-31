/**
 * 初始化配置模块
 * 负责合约的初始参数设置和地址配置
 */

const crypto = require('crypto');

async function getAllUserId(contracts, connectors) {
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
    userManagerConnectors
  } = connectors;

  const userId_data = await getUserId(
    userManagerConnectors.minter,
    userManagerConnectors.seller,
    userManagerConnectors.buyer,
    userManagerConnectors.buyer2,
    userManagerConnectors.completer,
  )

  return userId_data;
}

async function getUserId(
  userManager_minter,
  userManager_seller,
  userManager_buyer,
  userManager_buyer2,
  userManager_completer
) {
  const userId_minter = await userManager_minter.myUserId();
  const userId_seller = await userManager_seller.myUserId();
  const userId_buyer = await userManager_buyer.myUserId();
  const userId_buyer2 = await userManager_buyer2.myUserId();
  const userId_completer = await userManager_completer.myUserId();

  return {
    userId_minter,
    userId_seller,
    userId_buyer,
    userId_buyer2,
    userId_completer
  }
}

module.exports = {
  getAllUserId,
};
