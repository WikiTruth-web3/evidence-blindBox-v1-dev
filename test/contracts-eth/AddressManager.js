const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployBlindBoxFixture} = require("./fixtures/Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');

describe("AddressManager- 相关测试", function () {
  it("设置地址列表", async function () {
    const { 
      blindBox, exchange, userManager, addressManager,siweAuth, quoter, swapContract, fundManager, 
      buyer, minter, dao, wETH, wROSE, settlementToken, address_zero, wBTC,
      userManager_buyer, userManager_minter, userManager_DAO
    } = await loadFixture(deployBlindBoxFixture);

    const addressList = [
      blindBox.target, // dao
      exchange.target, // governance
      userManager.target, // daoFundManager
      address_zero, // userManager 原始值不变
      address_zero, // siweAuth 原始值不变
      address_zero, // blindBox 原始值不变
      wBTC.target, // exchange
      wETH.target, // fundManager
      quoter.address, // fundManager
    ]

    for (i; i< addressList; i++) {
      await addressManager.setMainContract(i,addressList[i]);
    }

    expect(await addressManager.getMainContract(0)).to.deep.equal(blindBox.target);
    expect(await addressManager.getMainContract(1)).to.deep.equal(exchange.target);
    expect(await addressManager.getMainContract(2)).to.deep.equal(userManager.target);

    expect(await addressManager.getMainContract(3)).to.deep.equal(userManager.target);
    expect(await addressManager.getMainContract(4)).to.deep.equal(siweAuth.address);
    expect(await addressManager.getMainContract(5)).to.deep.equal(blindBox.target);

    expect(await addressManager.getMainContract(6)).to.deep.equal(wBTC.target);
    expect(await addressManager.getMainContract(7)).to.deep.equal(wETH.target);
    

  });  





});

