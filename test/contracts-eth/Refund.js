const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployBlindBoxFixture } = require("./fixtures/Fixture.js");
const exp = require("constants");
const { timestampToDate, secondsToDhms } = require('../utils/timeToDate.js');
const TimeHelpers = require("./helpers");

// npx hardhat test test/contracts-eth/Refund.js 

describe("交易测试-退款相关测试", function () {

    it("1-Sell-申请退款-未过期", async function () {
    const { 
      exchange_minter,exchange_buyer, address_zero,
      settlementToken,blindBox, 
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_buyer.buy(1);
    await exchange_buyer.requestRefund(1);
    expect(await blindBox.getStatus(1)).to.equal(TimeHelpers.Status.Refunding);

  });


  it("2-Sell-申请退款（过期）-- Status.Delaying", async function () {
    const { 
      exchange_minter,exchange_buyer, address_zero,
      settlementToken,blindBox, 
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.sell(2, address_zero, 2000);
    await exchange_buyer.buy(2);
    await time.increase(30 * 24 * 60 * 60);
    await expect(exchange_buyer.requestRefund(2)).to.be.revertedWithCustomError(exchange,"DeadlineIsOver");
    expect(await blindBox.getStatus(2)).to.equal(TimeHelpers.Status.Paid);

  });

  it("3-Sell-审核退款（未过期）", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_DAO,
      settlementToken,blindBox, address_zero,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.sell(2, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.buy(2);
    // ========================== 申请退款 ==========================
    // 在退款期内，
    await exchange_buyer.requestRefund(1);
    expect(await blindBox.getStatus(1)).to.equal(TimeHelpers.Status.Refunding);

    await exchange_buyer.requestRefund(2);
    expect(await blindBox.getStatus(2)).to.equal(TimeHelpers.Status.Refunding);

    // ========================== 审核退款 ==========================
    // 未超时
    await exchange_DAO.agreeRefund(1);
    expect(await blindBox.getStatus(1)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(1)).to.equal(true); 

    await exchange_DAO.refuseRefund(2);
    expect(await blindBox.getStatus(2)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(2)).to.equal(false); 
  });

  it("4-Sell-审核退款（过期）-- 退款成功", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_DAO,
      settlementToken,blindBox, address_zero,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.sell(3, address_zero, 2000);
    await exchange_minter.sell(4, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.buy(3);
    await exchange_buyer.buy(4);
    // ========================== 申请退款 ==========================

    await exchange_buyer.requestRefund(3);
    await exchange_buyer.requestRefund(4);

    // ========================== 审核退款 ==========================
    // 超过退款期 -- 状态直接完成
    await time.increase(30 * 24 * 60 * 60);
    await exchange_DAO.agreeRefund(3);
    await exchange_DAO.refuseRefund(4); // NOTE 超时不需要检查DAO
    expect(await blindBox.getStatus(3)).to.equal(TimeHelpers.Status.Published);
    expect(await blindBox.getStatus(4)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(3)).to.equal(true); 
    expect(await exchange.refundPermit(4)).to.equal(true); 
    
  });


  it("5-拍卖-申请退款（未过期）", async function () {
    const { 
      exchange_minter,exchange_buyer, address_zero,
      settlementToken,blindBox, 
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.auction(3, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.bid(3);
    await time.increase(40 * 24 * 60 * 60); 
    // ========================== 申请退款 ==========================
    await exchange_buyer.requestRefund(3);
    expect(await blindBox.getStatus(3)).to.equal(TimeHelpers.Status.Refunding);
    expect(await exchange.refundPermit(3)).to.equal(false); 
  });

    it("6-拍卖-申请退款(过期)-状态进入Delaying", async function () {
    const { 
      exchange_minter,exchange_buyer, address_zero,
      settlementToken,blindBox, 
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.auction(4, address_zero, 2000);
    await exchange_buyer.bid(4);
    // NOTE 30 + 7 
    await time.increase(60 * 24 * 60 * 60); 
    await expect(exchange_buyer.requestRefund(2)).to.be.revertedWithCustomError(exchange,"InvalidStatus");
    expect(await blindBox.getStatus(4)).to.equal(TimeHelpers.Status.Paid); // 完成状态
  });

  it("7-拍卖-审核退款-未过期", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_DAO,
      settlementToken,blindBox, address_zero,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.auction(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    // ========================== 购买1 ==========================
    await exchange_buyer.bid(1);
    await exchange_buyer.bid(2);

    await time.increase(40 * 24 * 60 * 60); 
    // ========================== 申请退款 ==========================
    await exchange_buyer.requestRefund(1);
    await exchange_buyer.requestRefund(2);
    // ========================== 审核退款 ==========================
    await exchange_DAO.agreeRefund(1);
    await exchange_DAO.refuseRefund(2);
    expect(await blindBox.getStatus(1)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(1)).to.equal(true); 
    expect(await blindBox.getStatus(2)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(2)).to.equal(false); 
  });

  it("8-拍卖-审核退款-过期-结果退款", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_DAO,
      settlementToken,blindBox, address_zero,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.auction(3, address_zero, 2000);
    await exchange_minter.auction(4, address_zero, 2000);

    // ========================== 购买1 ==========================
    await exchange_buyer.bid(3);
    await exchange_buyer.bid(4);

    await time.increase(40 * 24 * 60 * 60); 
    // ========================== 申请退款 ==========================
    // 在退款期内，
    await exchange_buyer.requestRefund(3);
    await exchange_buyer.requestRefund(4);

    // ========================== 审核退款 ==========================
    await time.increase(40 * 24 * 60 * 60); 

    await exchange_DAO.agreeRefund(3);
    await exchange_DAO.refuseRefund(4);
    expect(await blindBox.getStatus(3)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(4)).to.equal(true); 
    expect(await blindBox.getStatus(3)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(4)).to.equal(true); 
  });

  it("9-审核退款-未过期-buyer不能主动同意--过期-任何人都可以操作同意退款", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_DAO,
      settlementToken,blindBox, address_zero,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.auction(1, address_zero, 2000);

    // ========================== 购买1 ==========================
    await exchange_buyer.bid(1);

    await time.increase(40 * 24 * 60 * 60); 
    // ========================== 申请退款 ==========================
    await exchange_buyer.requestRefund(1);
    // ========================== 审核退款 ==========================
    await expect(exchange_buyer.agreeRefund(1)).to.be.reverted;

    await time.increase(40 * 24 * 60 * 60); 
    await exchange_buyer.agreeRefund(1);

  });

});

