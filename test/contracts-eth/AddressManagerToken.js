const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');

describe("AddressManager-Token- 相关测试", function () {
  it("移除官方代币--失败", async function () {
    const { 
      truthBox, exchange, fundManager, userManager, addressManager,
      buyer, minter, dao, settlementToken, wBTC, wETH, address_zero,
      userManager_buyer, userManager_minter, userManager_DAO
    } = await loadFixture(deployTruthBoxFixture);

    expect(await addressManager.isSettlementToken(settlementToken.target)).to.equal(true);
    // 尝试移除官方代币，失败
    await expect(addressManager.removeToken(settlementToken.target)).to.be.revertedWithCustomError(addressManager, "IsSettlementToken");

  });  

  it("修改官方代币", async function () {
    const { 
      truthBox, exchange, userManager, addressManager, quoter, swapContract, fundManager, 
      buyer, minter, dao, wETH, wROSE, settlementToken, address_zero, wBTC,
      userManager_buyer, userManager_minter, userManager_DAO
    } = await loadFixture(deployTruthBoxFixture);

    await addressManager.setSettlementToken(wETH.target);

    expect(await addressManager.isSettlementToken(wETH.target)).to.equal(true);
    expect(await addressManager.isSettlementToken(settlementToken.target)).to.equal(false);

    // 重新还原
    await addressManager.setSettlementToken(settlementToken.target);
    expect(await addressManager.isSettlementToken(wETH.target)).to.equal(false);
    expect(await addressManager.isSettlementToken(settlementToken.target)).to.equal(true);

  });

  it("尝试将官方代币添加---失败", async function () {
    const { 
      truthBox, exchange, fundManager, userManager, addressManager,
      buyer, minter, dao, settlementToken, wBTC, wETH, address_zero,
      userManager_buyer, userManager_minter, userManager_DAO
    } = await loadFixture(deployTruthBoxFixture);

    await expect(addressManager.addToken(settlementToken.target)).to.be.revertedWithCustomError(addressManager, "TokenIsActive");

  }); 

  it("尝试添加0地址代币---失败", async function () {
    const { 
      truthBox, exchange, fundManager, userManager, addressManager,
      buyer, minter, dao, settlementToken, wBTC, wETH, address_zero,
      userManager_buyer, userManager_minter, userManager_DAO
    } = await loadFixture(deployTruthBoxFixture);
    // 设置0地址为官方代币，失败
    await expect(addressManager.setSettlementToken(address_zero)).to.be.revertedWithCustomError(addressManager, "InvalidAddress");

    await expect(addressManager.addToken(address_zero)).to.be.revertedWithCustomError(addressManager, "InvalidAddress");

  }); 

  it("addToken代币管理", async function () {
    const { 
      truthBox, exchange, fundManager, userManager, addressManager,
      buyer, minter, dao, settlementToken, wBTC, wETH, address_zero,
      userManager_buyer, userManager_minter, userManager_DAO
    } = await loadFixture(deployTruthBoxFixture);

    expect(await addressManager.isTokenSupported(wETH.target)).to.equal(false);
    // 添加代币
    await addressManager.addToken(wETH.target);

    const tokenList = await addressManager.getTokenList();
    expect(tokenList[0]).to.equal(wBTC.target);
    expect(tokenList[1]).to.equal(wETH.target);

    // 移除代币
    await addressManager.removeToken(wETH.target);
    const tokenList2 = await addressManager.getTokenList();
    // 只剩下一个 wBTC
    expect(tokenList2.length).to.equal(1);
    expect(tokenList2[0]).to.equal(wBTC.target);
    expect(await addressManager.isTokenSupported(wETH.target)).to.equal(false);
    // 重复移除，失败
    await expect(addressManager.removeToken(wETH.target)).to.be.revertedWithCustomError(addressManager, "TokenIsNotActive");

  });  

});

