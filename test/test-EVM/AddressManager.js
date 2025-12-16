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
 * 1. 设置地址列表
 * 2. 修改官方代币
 * 3. 添加保留地址
 * 
 */

describe("AddressManager- 相关测试", function () {
  it("设置地址列表", async function () {
    const { 
      truthBox, exchange, userId, addressManager,siweAuth, quoter, swapContract, fundManager, truthNFT,
      buyer, minter, dao, otherToken, otherToken2, officialToken, address_zero, testToken,
      userId_buyer, userId_minter, userId_DAO
    } = await loadFixture(deployTruthBoxFixture);

    const tokenList = [
      truthBox.target, // dao
      exchange.target, // governance
      userId.target, // daoFundManager
      address_zero, // userId 原始值不变
      address_zero, // siweAuth 原始值不变
      address_zero, // truthBox 原始值不变
      officialToken.target, // truthNFT
      testToken.target, // exchange
      otherToken.target, // fundManager
      otherToken2.target, // swapContract
      address_zero, // quoter 原始值不变
    ]

    await addressManager.setAddressList(tokenList);

    expect(await addressManager.dao()).to.deep.equal(truthBox.target);
    expect(await addressManager.governance()).to.deep.equal(exchange.target);
    expect(await addressManager.daoFundManager()).to.deep.equal(userId.target);

    expect(await addressManager.userId()).to.deep.equal(userId.target);
    expect(await addressManager.siweAuth()).to.deep.equal(siweAuth.address);
    expect(await addressManager.truthBox()).to.deep.equal(truthBox.target);

    expect(await addressManager.exchange()).to.deep.equal(testToken.target);
    expect(await addressManager.fundManager()).to.deep.equal(otherToken.target);
    expect(await addressManager.swapContract()).to.deep.equal(otherToken2.target);
    expect(await addressManager.quoter()).to.deep.equal(quoter.address);

  });  

  it("修改官方代币", async function () {
    const { 
      truthBox, exchange, userId, addressManager, quoter, swapContract, fundManager, truthNFT,
      buyer, minter, dao, otherToken, otherToken2, officialToken, address_zero, testToken,
      userId_buyer, userId_minter, userId_DAO
    } = await loadFixture(deployTruthBoxFixture);

    await addressManager.setOfficialToken(otherToken.target);

    expect(await addressManager.isOfficialToken(otherToken.target)).to.equal(true);
    expect(await addressManager.isOfficialToken(officialToken.target)).to.equal(false);

    expect(await addressManager.getTokenByIndex(0)).to.deep.equal(otherToken.target);

    await addressManager.setOfficialToken(officialToken.target);

    expect(await addressManager.isOfficialToken(otherToken.target)).to.equal(false);
    expect(await addressManager.isOfficialToken(officialToken.target)).to.equal(true);

    expect(await addressManager.getTokenByIndex(0)).to.deep.equal(officialToken.target);

  });

  it("移除官方代币-失败", async function () {
    const { 
      truthBox, exchange, userId, addressManager, quoter, swapContract, fundManager, truthNFT,
      buyer, minter, dao, otherToken, otherToken2, officialToken, address_zero, testToken,
      userId_buyer, userId_minter, userId_DAO
    } = await loadFixture(deployTruthBoxFixture);

    expect(await addressManager.isOfficialToken(officialToken.target)).to.equal(true);

    await expect(addressManager.removeToken(officialToken.target)).to.be.revertedWithCustomError(addressManager, "CannotRemoveOfficialToken");

    
  });

  it("添加代币-成功", async function () {
    const { 
      truthBox, exchange, userId, addressManager, quoter, swapContract, fundManager, truthNFT,
      buyer, minter, dao, otherToken, otherToken2, officialToken, address_zero, testToken,
      userId_buyer, userId_minter, userId_DAO
    } = await loadFixture(deployTruthBoxFixture);

    await addressManager.addToken(otherToken.target);

    expect(await addressManager.isTokenSupported(otherToken.target)).to.equal(true);

    expect(await addressManager.getTokenByIndex(2)).to.deep.equal(otherToken.target);

    await addressManager.addToken(otherToken2.target);

    expect(await addressManager.isTokenSupported(otherToken2.target)).to.equal(true);

    expect(await addressManager.getTokenByIndex(3)).to.deep.equal(otherToken2.target);

    
  });

  it("移除代币", async function () {
    const { 
      truthBox, exchange, userId, addressManager, quoter, swapContract, fundManager, truthNFT,
      buyer, minter, dao, otherToken, otherToken2, officialToken, address_zero, testToken,
      userId_buyer, userId_minter, userId_DAO
    } = await loadFixture(deployTruthBoxFixture);

    expect(await addressManager.isTokenSupported(testToken.target)).to.equal(true);

    await addressManager.removeToken(testToken.target);

    expect(await addressManager.isTokenSupported(testToken.target)).to.equal(false);

    expect(await addressManager.getTokenByIndex(1)).to.deep.equal(testToken.target);

    // 重复移除，失败
    await expect(addressManager.removeToken(testToken.target)).to.be.revertedWithCustomError(addressManager, "TokenIsNotActive");

    // 添加代币后-
    await addressManager.addToken(otherToken.target);
    expect(await addressManager.isTokenSupported(otherToken.target)).to.equal(true);
    expect(await addressManager.isTokenSupported(testToken.target)).to.equal(false);
    expect(await addressManager.getTokenByIndex(1)).to.deep.equal(testToken.target);
    expect(await addressManager.getTokenByIndex(2)).to.deep.equal(otherToken.target);

    

    
  });






});

