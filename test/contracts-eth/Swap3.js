const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture } = require("./Fixture.js");
const exp = require("constants");
const { timestampToDate, secondsToDhms } = require('../utils/timeToDate.js');
const TimeHelpers = require("./helpers");

describe("交易测试-退款相关测试", function () {

  it("12-Sell-申请退款-在期-过期", async function () {
    const { 
      exchange_minter,exchange_buyer, address_zero,
      settlementToken,truthBox, 
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.sell(2, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.buy(2);
    // ========================== 申请退款 ==========================
    // 在退款期内，
    await exchange_buyer.requestRefund(1);
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Refunding);
    expect(await exchange.refundPermit(1)).to.equal(false); 

    // 超过退款期 -- 状态直接完成
    await time.increase(20 * 24 * 60 * 60);
    await exchange_buyer.requestRefund(2);
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Delaying);
    
    // ========================== 尝试再次申请退款 ==========================
    // 已经申请过退款，不能再次申请
    await expect(exchange_buyer.requestRefund(1)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(2)).to.be.reverted;

  });

  it("12-Sell-审核退款-在期-过期", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_DAO,
      settlementToken,truthBox, address_zero,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.sell(2, address_zero, 2000);
    await exchange_minter.sell(3, address_zero, 2000);
    await exchange_minter.sell(4, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.buy(2);
    await exchange_buyer.buy(3);
    await exchange_buyer.buy(4);
    // ========================== 申请退款 ==========================
    // 在退款期内，
    await exchange_buyer.requestRefund(1);
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Refunding);
    expect(await exchange.refundPermit(1)).to.equal(false); 

    await exchange_buyer.requestRefund(2);
    await exchange_buyer.requestRefund(3);
    await exchange_buyer.requestRefund(4);
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Refunding);
    expect(await exchange.refundPermit(2)).to.equal(false); 

    // ========================== 审核退款 ==========================
    // 未超时
    await exchange_DAO.agreeRefund(1);
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(1)).to.equal(true); 

    await exchange_DAO.refuseRefund(2);
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Delaying);
    expect(await exchange.refundPermit(2)).to.equal(false); 

    // 超过退款期 -- 状态直接完成
    await time.increase(30 * 24 * 60 * 60);
    await exchange_DAO.agreeRefund(3);
    await exchange_buyer.refuseRefund(4); // 超时不需要检查DAO
    expect(await truthBox.getStatus(3)).to.equal(TimeHelpers.Status.Published);
    expect(await truthBox.getStatus(4)).to.equal(TimeHelpers.Status.Published);
    
    // ========================== 尝试再次执行，revert ==========================
    // 已经申请过退款，不能再次申请
    await expect(exchange_buyer.requestRefund(1)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(2)).to.be.reverted;

    await expect(exchange_DAO.agreeRefund(1)).to.be.reverted;
    await expect(exchange_DAO.agreeRefund(2)).to.be.reverted;


  });

  it("12-拍卖-申请退款-在期-过期", async function () {
    const { 
      exchange_minter,exchange_buyer, address_zero,
      settlementToken,truthBox, 
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.auction(3, address_zero, 2000);
    await exchange_minter.auction(4, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.bid(3);
    await exchange_buyer.bid(4);

    await time.increase(40 * 24 * 60 * 60); 

    // ========================== 申请退款 ==========================
    // 在退款期内，
    await exchange_buyer.requestRefund(3);
    expect(await truthBox.getStatus(3)).to.equal(TimeHelpers.Status.Refunding);
    expect(await exchange.refundPermit(3)).to.equal(false); 
    // 超过退款期限
    await time.increase(40 * 24 * 60 * 60);
    await exchange_buyer.requestRefund(4);
    expect(await truthBox.getStatus(4)).to.equal(TimeHelpers.Status.Delaying); // 完成状态
    expect(await exchange.refundPermit(4)).to.equal(false); 

    // ========================== 尝试再次申请退款 ==========================
    // 已经申请过退款，不能再次申请
    await expect(exchange_buyer.requestRefund(3)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(4)).to.be.reverted;
  });

  it("12-拍卖-审核退款-在期-过期", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_DAO,
      settlementToken,truthBox, address_zero,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.auction(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);
    await exchange_minter.auction(3, address_zero, 2000);
    await exchange_minter.auction(4, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.bid(1);
    await exchange_buyer.bid(2);
    await exchange_buyer.bid(3);
    await exchange_buyer.bid(4);

    await time.increase(40 * 24 * 60 * 60); 

    // ========================== 申请退款 ==========================
    // 在退款期内，
    await exchange_buyer.requestRefund(1);
    await exchange_buyer.requestRefund(2);
    await exchange_buyer.requestRefund(3);
    await exchange_buyer.requestRefund(4);
    expect(await truthBox.getStatus(3)).to.equal(TimeHelpers.Status.Refunding);
    expect(await exchange.refundPermit(3)).to.equal(false); 

    // ========================== 审核退款 ==========================
    await exchange_DAO.agreeRefund(1);
    await exchange_DAO.refuseRefund(2);
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Published);
    expect(await exchange.refundPermit(1)).to.equal(true); 
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Delaying);
    expect(await exchange.refundPermit(2)).to.equal(false); 

    // 超过退款期限
    await time.increase(40 * 24 * 60 * 60);
    await exchange_DAO.agreeRefund(3);
    await exchange_buyer.agreeRefund(4); //超过期限不会检查DAO
    
    expect(await truthBox.getStatus(3)).to.equal(TimeHelpers.Status.Published); // 完成状态
    expect(await truthBox.getStatus(4)).to.equal(TimeHelpers.Status.Published); // 完成状态
    expect(await exchange.refundPermit(4)).to.equal(true); 

    // ========================== 尝试再次申请退款 ==========================
    // 已经申请过退款，不能再次申请
    await expect(exchange_buyer.requestRefund(3)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(4)).to.be.reverted;
  });

  it("14-购买-取消退款-黑名单", async function () {
    const { 
      truthBox_minter, truthBox_other, exchange_minter,exchange_buyer,bytes32_buyer,
      settlementToken, address_zero, bytes32_zero,
      truthBox, truthBox_DAO,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.sell(2, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.buy(2);

    // ========================== 申请退款 ==========================
    await exchange_buyer.requestRefund(1);
    await exchange_buyer.requestRefund(2);
    // ========================== 取消退款 ==========================
    await exchange_buyer.cancelRefund(1);
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Delaying);
    // 黑名单 --- 
    await truthBox_DAO.addToBlacklist(2);
    await expect(exchange_buyer.cancelRefund(2)).to.be.reverted;
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Blacklisted); // Refunding
    expect(await exchange.refundPermit(2)).to.equal(true);

    // ========================== 尝试再次取消退款 ！！！出错！！！==========================
    // 已经申请过退款，不能再次申请
    await expect(exchange_buyer.cancelRefund(1)).to.be.reverted;
    await expect(exchange_buyer.cancelRefund(2)).to.be.reverted;

  });

  it("14-竞拍-同意退款-黑名单", async function () {
    const { 
      truthBox_minter, truthBox_other, exchange_minter,exchange_buyer,bytes32_buyer,
      settlementToken, address_zero, exchange_DAO,
      truthBox, truthBox_DAO,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.auction(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.bid(1);
    await exchange_buyer.bid(2);
    // ========================== 确认1 ==========================
    await time.increase(35 * 24 * 60 * 60);

    // ========================== 申请退款 ==========================
    await exchange_buyer.requestRefund(1);
    await exchange_buyer.requestRefund(2);
    // 将2和4号加入黑名单
    // ========================== 取消退款 ==========================
    await exchange_DAO.agreeRefund(1);
    // 由于超时发货，导致有退款产生
    expect(await exchange.refundPermit(1)).to.equal(true);
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Published);
    // 黑名单 --- 
    await truthBox_DAO.addToBlacklist(2);
    await expect(exchange_buyer.agreeRefund(2)).to.be.reverted;
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Blacklisted); // Refunding
    expect(await exchange.refundPermit(2)).to.equal(true);

    // ========================== 尝试再次取消退款 ！！！出错！！！==========================
    // 已经申请过退款，不能再次申请
    await expect(exchange_buyer.cancelRefund(1)).to.be.reverted;
    await expect(exchange_buyer.cancelRefund(2)).to.be.reverted;

  });

});

