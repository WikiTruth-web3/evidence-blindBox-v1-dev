const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');

describe("AddressManager- 相关测试", function () {
  it("设置地址列表", async function () {
    const { 
      truthBox, exchange, userManager, addressManager,siweAuth, quoter, swapContract, fundManager, 
      buyer, minter, dao, wETH, wROSE, settlementToken, address_zero, wBTC,
      userManager_buyer, userManager_minter, userManager_DAO
    } = await loadFixture(deployTruthBoxFixture);

    const tokenList = [
      truthBox.target, // dao
      exchange.target, // governance
      userManager.target, // daoFundManager
      address_zero, // userManager 原始值不变
      address_zero, // siweAuth 原始值不变
      address_zero, // truthBox 原始值不变
      wBTC.target, // exchange
      wETH.target, // fundManager
      quoter.address, // fundManager
    ]

    await addressManager.setAddressList(tokenList);

    expect(await addressManager.dao()).to.deep.equal(truthBox.target);
    expect(await addressManager.governance()).to.deep.equal(exchange.target);
    expect(await addressManager.daoFundManager()).to.deep.equal(userManager.target);

    expect(await addressManager.userManager()).to.deep.equal(userManager.target);
    expect(await addressManager.siweAuth()).to.deep.equal(siweAuth.address);
    expect(await addressManager.truthBox()).to.deep.equal(truthBox.target);

    expect(await addressManager.exchange()).to.deep.equal(wBTC.target);
    expect(await addressManager.fundManager()).to.deep.equal(wETH.target);
    

  });  





});

