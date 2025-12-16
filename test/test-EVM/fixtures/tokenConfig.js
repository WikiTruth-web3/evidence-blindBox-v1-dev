/**
 * 代币配置模块
 * 负责代币的铸造、授权和流动性配置
 */

async function configureTokens(signers, contracts, connectors) {
  const { admin, buyer, buyer2, minter, other, other2 } = signers;
  const { testToken, officialToken, swapContract, addressManager, fundManager } = contracts;
  const { tokenConnectors } = connectors;

  // 铸造测试代币
  await testToken.mint(admin.address);
  await testToken.mint(buyer.address);
  await testToken.mint(buyer2.address);
  await testToken.mint(minter.address);
  await testToken.mint(other.address);

  // 铸造官方代币
  await officialToken.mint(admin.address);
  await tokenConnectors.officialToken.minter.mint(minter.address);
  await tokenConnectors.officialToken.other.mint(other.address);
  await tokenConnectors.officialToken.other2.mint(other2.address);
  await tokenConnectors.officialToken.buyer.mint(buyer.address);
  await tokenConnectors.officialToken.buyer2.mint(buyer2.address);

  // 设置代币授权到FundManager
  await tokenConnectors.officialToken.other.approve(fundManager.target, 100000000);
  await tokenConnectors.officialToken.minter.approve(fundManager.target, 100000000);
  await tokenConnectors.officialToken.buyer.approve(fundManager.target, 100000000);
  await tokenConnectors.officialToken.buyer2.approve(fundManager.target, 100000000);

  await tokenConnectors.testToken.buyer.approve(fundManager.target, 100000000);
  await tokenConnectors.testToken.buyer2.approve(fundManager.target, 100000000);

  // 设置代币授权到SwapContract
  await officialToken.approve(swapContract.target, 1000000000000000);
  await tokenConnectors.officialToken.minter.approve(swapContract.target, 100000000);
  await tokenConnectors.officialToken.buyer.approve(swapContract.target, 100000000);
  await tokenConnectors.officialToken.other.approve(swapContract.target, 100000000);

  await testToken.approve(swapContract.target, 1000000000000000);
  await tokenConnectors.testToken.buyer.approve(swapContract.target, 100000000);
  await tokenConnectors.testToken.minter.approve(swapContract.target, 100000000);
  await tokenConnectors.testToken.other.approve(swapContract.target, 100000000);

  // 添加代币到地址管理器
  await addressManager.addToken(officialToken.target);
  await addressManager.addToken(testToken.target);

  // 配置交换合约
  await swapContract.setToken(officialToken.target, testToken.target);
  await swapContract.addLiquidity(100000000000000, 10000000000000); // 10:1 ratio
}

module.exports = {
  configureTokens
};
