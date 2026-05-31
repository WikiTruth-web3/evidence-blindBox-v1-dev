const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployBlindBoxFixture} = require("./fixtures/Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');

// npx hardhat test test/contracts-eth/AddressManager.js

describe("AddressManager- 相关测试", function () {
  it("设置地址列表", async function () {
    const { 
      blindBox, exchange, userManager, addressManager,siweAuth, fundManager, 
      buyer, minter, dao, wETH, wROSE, settlementToken, address_zero, wBTC,
      userManager_buyer, userManager_minter, userManager_DAO, forwarder
    } = await loadFixture(deployBlindBoxFixture);

    const addressList = [
      blindBox.target, // blindBox
      exchange.target, // exchange
      userManager.target, // fundManager
      address_zero, // userManager 
      address_zero, // siweAuth 
      address_zero, // forwarder
      wBTC.target, // dao
      wETH.target, // dao_treasury
      wROSE.target, // governance
    ]

    for (let i = 0; i < addressList.length; i++) {
      await addressManager.setMainContract(i, addressList[i]);
    }

    expect(await addressManager.getMainContract(0)).to.deep.equal(blindBox.target);
    expect(await addressManager.getMainContract(1)).to.deep.equal(exchange.target);
    expect(await addressManager.getMainContract(2)).to.deep.equal(userManager.target);

    expect(await addressManager.getMainContract(3)).to.deep.equal(userManager.target);
    expect(await addressManager.getMainContract(4)).to.deep.equal(siweAuth.address);
    expect(await addressManager.getMainContract(5)).to.deep.equal(forwarder.target);

    expect(await addressManager.getMainContract(6)).to.deep.equal(wBTC.target);
    expect(await addressManager.getMainContract(7)).to.deep.equal(wETH.target);
    

  });  





});

