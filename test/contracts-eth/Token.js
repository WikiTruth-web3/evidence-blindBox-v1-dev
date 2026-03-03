const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');
/**
 * 测试合约：AddressManager.sol
 * 主要测试内容：
 * 1. 设置官方代币
 * 2. 检查官方代币
 * 3. 检查代币是否被支持
 * 4. 检查代币是否是官方代币
 */

describe("Token- 相关测试", function () {
  it("测试代币管理", async function () {
    const { 
      truthBox, exchange, fundManager, userId, addressManager,
      buyer, minter, dao, officialToken, testToken, otherToken, address_zero,
      userId_buyer, userId_minter, userId_DAO
    } = await loadFixture(deployTruthBoxFixture);

    expect(await addressManager.isTokenSupported(otherToken.target)).to.equal(false);
    expect(await addressManager.isOfficialToken(otherToken.target)).to.equal(false);
    // 添加代币
    await addressManager.addToken(otherToken.target);

    const tokenList = await addressManager.getTokenList();
    expect(tokenList[0]).to.equal(officialToken.target);
    expect(tokenList[1]).to.equal(testToken.target);
    expect(tokenList[2]).to.equal(otherToken.target);

    // 移除代币
    await addressManager.removeToken(otherToken.target);
    const tokenList2 = await addressManager.getTokenList();
    // 移除代币后，代币依然在列表中，但是不再支持。
    expect(tokenList2[2]).to.equal(otherToken.target);
    expect(await addressManager.isTokenSupported(otherToken.target)).to.equal(false);
    // 重复移除，失败
    await expect(addressManager.removeToken(otherToken.target)).to.be.revertedWithCustomError(addressManager, "TokenIsNotActive");

    // 设置官方代币
    await addressManager.setOfficialToken(otherToken.target);
    const tokenList3 = await addressManager.getTokenList();
    expect(tokenList3[0]).to.equal(otherToken.target);
    // 设置官方代币后，官方代币不再支持。
    expect(await addressManager.isTokenSupported(officialToken.target)).to.equal(false);
    expect(await addressManager.isOfficialToken(otherToken.target)).to.equal(true);

    // 恢复官方代币
    await addressManager.setOfficialToken(officialToken.target);
    const tokenList4 = await addressManager.getTokenList();
    expect(tokenList4[0]).to.equal(officialToken.target);
    expect(await addressManager.isTokenSupported(otherToken.target)).to.equal(false);
    expect(await addressManager.isOfficialToken(officialToken.target)).to.equal(true);

    // 尝试移除官方代币，失败
    await expect(addressManager.removeToken(officialToken.target)).to.be.revertedWithCustomError(addressManager, "CannotRemoveOfficialToken");
    // 尝试重复添加已支持的代币，失败
    await expect(addressManager.addToken(officialToken.target)).to.be.revertedWithCustomError(addressManager, "TokenIsActive");
    // 尝试重复添加未支持的代币，成功
    await addressManager.addToken(otherToken.target);
    expect(await addressManager.isTokenSupported(otherToken.target)).to.equal(true);

  });  

  // it("测试移除officialToken", async function () {
  //   const { 
  //     truthBox, exchange, fundManager, userId, addressManager,
  //     buyer, minter, dao, officialToken, testToken, otherToken, address_zero,
  //     userId_buyer, userId_minter, userId_DAO
  //   } = await loadFixture(deployTruthBoxFixture);


});

