const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const crypto = require('crypto'); // 引入crypto库 nodejs内置的加密库
const { Status } = require("./helpers.js");

describe("TruthBox_Public测试", function () {

  // 只测试黑名单功能，其他测试暂时跳过
  it("出售/拍卖---buyer购买---主动公开---过期公开", async function () {
    const { 
      admin, minter, dao, truthBox, testToken,
      truthBox_minter, truthBox_buyer, exchange_minter,
      exchange_buyer, exchange_DAO, fundManager, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    await exchange_minter.sell(3, address_zero, 2000);
    await exchange_minter.auction(4, address_zero, 2000);

    // ========================== 购买 ==========================
    await exchange_buyer.buy(1)
    await exchange_buyer.bid(2)
    await exchange_buyer.buy(3)
    await exchange_buyer.bid(4)
    await time.increase(80*24*60*60);

    await exchange_buyer.completeOrder(1)
    await exchange_buyer.completeOrder(2)
    await exchange_buyer.completeOrder(3)
    await exchange_buyer.completeOrder(4)

    expect(await truthBox.getStatus(1)).to.equal(Status.InSecrecy);
    expect(await truthBox.getStatus(2)).to.equal(Status.InSecrecy);

    // ========================== 公开 ==========================
    // minter 无法执行公开操作
    await expect(truthBox_minter.publishByMinter(1)).to.be.reverted;

    await truthBox_buyer.publishByBuyer(1)
    await truthBox_buyer.publishByBuyer(2)
    // 调用PublicNoBuyer函数，传入2号Box
    expect(await truthBox.getStatus(1)).to.equal(Status.Published);
    expect(await truthBox.getStatus(2)).to.equal(Status.Published);

    await time.increase(380*24*60*60);

    expect(await truthBox.getStatus(3)).to.equal(Status.Published);
    expect(await truthBox.getStatus(4)).to.equal(Status.Published);
  });

  it("出售/拍卖-无buyer---到期直接是公开状态", async function () {
    const { 
      admin, minter, dao, truthBox, testToken,
      truthBox_minter, truthBox_DAO, exchange_minter, 
      exchange_buyer, exchange_DAO, fundManager, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    // ========================== 公开other ==========================
    await time.increase(40*24*60*60);
    
    expect(await truthBox.getStatus(1)).to.equal(Status.Selling);
    expect(await truthBox.getStatus(2)).to.equal(Status.Published);
    // 再次调用则报错

    await time.increase(340*24*60*60);
    expect(await truthBox.getStatus(1)).to.equal(Status.Published);

  });

  it("出售/拍卖---minter无法执行公开！", async function () {
    const { 
      admin, minter, dao, buyer, truthBox,testToken,
      truthBox_minter, truthBox_DAO, exchange_minter, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    // 后移20天
    await time.increase(20*24*60*60);
    expect(await truthBox.getStatus(2)).to.equal(Status.Auctioning);

    // ========================== 公开 ==========================
    await expect(truthBox_minter.publishByMinter(2)).to.be.reverted;
    
    await time.increase(160*24*60*60);
    expect(await truthBox.getStatus(1)).to.equal(Status.Selling);
    await expect(truthBox_minter.publishByMinter(2)).to.be.reverted;

  });

});

