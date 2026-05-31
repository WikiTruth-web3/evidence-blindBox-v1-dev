/**
 * 代币配置模块
 * 负责代币的铸造、授权和流动性配置
 */

async function configureTokens(signers, contracts, connectors) {
  const { admin, buyer, buyer2, minter, other, other2 } = signers;
  const { wBTC, settlementToken, fundManager } = contracts;
  const { tokenConnectors } = connectors;

  // 铸造测试代币
  await wBTC.mint(admin.address);
  await wBTC.mint(buyer.address);
  await wBTC.mint(buyer2.address);
  await wBTC.mint(minter.address);
  await wBTC.mint(other.address);

  await settlementToken.mint(fundManager.target);

  // 铸造官方代币
  await settlementToken.mint(admin.address);
  await tokenConnectors.settlementToken.minter.mint(minter.address);
  await tokenConnectors.settlementToken.other.mint(other.address);
  await tokenConnectors.settlementToken.other2.mint(other2.address);
  await tokenConnectors.settlementToken.buyer.mint(buyer.address);
  await tokenConnectors.settlementToken.buyer2.mint(buyer2.address);

  // 设置代币授权到FundManager
  await tokenConnectors.settlementToken.other.approve(fundManager.target, ethers.MaxUint256);
  await tokenConnectors.settlementToken.minter.approve(fundManager.target, ethers.MaxUint256);
  await tokenConnectors.settlementToken.buyer.approve(fundManager.target, ethers.MaxUint256);
  await tokenConnectors.settlementToken.buyer2.approve(fundManager.target, ethers.MaxUint256);

  await tokenConnectors.wBTC.buyer.approve(fundManager.target, ethers.MaxUint256);
  await tokenConnectors.wBTC.buyer2.approve(fundManager.target, ethers.MaxUint256);
}

module.exports = {
  configureTokens
};
