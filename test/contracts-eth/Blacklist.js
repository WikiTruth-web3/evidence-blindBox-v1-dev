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

// npx hardhat test test/contracts-eth/BlackList.js

describe("交易测试-黑名单相关测试", function () {

    it("07-黑名单无法出售/拍卖", async function () {
    const { minter, blindBox, exchange_minter, settlementToken ,blindBox_DAO,
      blindBox_minter, address_zero,
    } = await loadFixture(deployBlindBoxFixture);
    
    await blindBox_DAO.addToBlacklist(1);
    await blindBox_DAO.addToBlacklist(2);
    // 时间增加360天
    await time.increase(360 * 24 * 60 * 60);
    // 应该抛出异常
    await expect(exchange_minter.sell(1, address_zero, 2000)).to.be.reverted;
    await expect(exchange_minter.auction(2, address_zero, 2000)).to.be.reverted;

  });

  it("14-购买-取消退款-黑名单", async function () {
    const { 
      blindBox_minter, blindBox_other, exchange_minter,exchange_buyer,bytes32_buyer,
      settlementToken, address_zero, bytes32_zero,fundManager_buyer, buyer,
      blindBox, blindBox_DAO,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

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
    expect(await blindBox.getStatus(1)).to.equal(TimeHelpers.Status.Delaying);
    await expect(fundManager_buyer.withdrawRefundAmounts(settlementToken.target,[1], buyer.address)).to.be.reverted;
    // 黑名单 --- 
    await blindBox_DAO.addToBlacklist(2);
    await expect(exchange_buyer.cancelRefund(2)).to.be.reverted;
    expect(await blindBox.getStatus(2)).to.equal(TimeHelpers.Status.Blacklisted); // Refunding
    expect(await exchange.refundPermit(2)).to.equal(true);



  });

  it("14-竞拍-同意退款-黑名单", async function () {
    const { 
      blindBox_minter, blindBox_other, exchange_minter,exchange_buyer,bytes32_buyer,
      settlementToken, address_zero, exchange_DAO,
      blindBox, blindBox_DAO,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

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
    expect(await blindBox.getStatus(1)).to.equal(TimeHelpers.Status.Published);
    // 黑名单 --- 
    await blindBox_DAO.addToBlacklist(2);
    await expect(exchange_buyer.agreeRefund(2)).to.be.reverted;
  });


  it("13-出售/拍卖--申请退款--添加黑名单--后续操作失败", async function () {
    const { 
      exchange_minter,exchange_buyer,bytes32_buyer, exchange_DAO,
      settlementToken, blindBox, blindBox_DAO, address_zero,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.sell(2, address_zero, 2000);
    await exchange_minter.auction(3, address_zero, 2000);
    await exchange_minter.auction(4, address_zero, 2000);

    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.buy(2);
    await exchange_buyer.bid(3);
    await exchange_buyer.bid(4);

        // ========================== 申请退款 ==========================
    await time.increase(10 * 24 * 60 * 60); 
    await exchange_buyer.requestRefund(1);
    await exchange_buyer.requestRefund(2);
    // 加入黑名单
    await blindBox_DAO.addToBlacklist(1);
    await blindBox_DAO.addToBlacklist(2);
    expect(await blindBox.getStatus(2)).to.equal(TimeHelpers.Status.Blacklisted); // 黑名单 --- 状态不变
    expect(await blindBox.getStatus(1)).to.equal(TimeHelpers.Status.Blacklisted); // 黑名单 --- 状态不变

    await expect(exchange_DAO.agreeRefund(1)).to.be.reverted;
    await expect(exchange_DAO.agreeRefund(2)).to.be.reverted;

    // NOTE 竞拍相关
    await time.increase(30 * 24 * 60 * 60); 
    await exchange_buyer.requestRefund(3);
    await exchange_buyer.requestRefund(4);
    // 加入黑名单
    await blindBox_DAO.addToBlacklist(3);
    await blindBox_DAO.addToBlacklist(4);

    await expect(exchange_DAO.agreeRefund(3)).to.be.reverted;
    await expect(exchange_DAO.agreeRefund(4)).to.be.reverted;

    // ========================== 验证退款 ==========================
        // 黑名单 --- 直接获得退款
    expect(await exchange.refundPermit(3)).to.equal(true); 
    expect(await exchange.refundPermit(4)).to.equal(true); // 黑名单

    // ========================== 尝试再次申请退款 ==========================
    // 已经申请过退款，不能再次申请
    await expect(exchange_buyer.requestRefund(1)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(2)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(3)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(4)).to.be.reverted;

  });


  it("14-交易完成后-添加黑名单-后续操作失败", async function () {
    const { 
      blindBox_minter, blindBox_other, exchange_minter,exchange_buyer,blindBox_buyer,
      settlementToken, address_zero, bytes32_zero,
      blindBox, blindBox_DAO,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);
    // ========================== 购买1 ==========================

    await exchange_buyer.buy(1);
    await exchange_buyer.bid(2);
    // ========================== 申请退款 ==========================

    await time.increase(35*24*60*60)
    await exchange_buyer.completeOrder(1);
    await exchange_buyer.completeOrder(2);
    // 将2和4号加入黑名单
    await blindBox_DAO.addToBlacklist(1);
    await blindBox_DAO.addToBlacklist(2);

    // ========================== 尝试再次取消退款 ！！！出错！！！==========================
    // 已经申请过退款，不能再次申请
    await expect(blindBox_buyer.delay(1)).to.be.reverted;
    await expect(blindBox_buyer.delay(2)).to.be.reverted;

    await expect(blindBox_buyer.publishByBuyer(1)).to.be.reverted;
    await expect(blindBox_buyer.publishByBuyer(2)).to.be.reverted;

  });

  it("14-出售/竞拍-添加黑名单-无法购买-提款失败", async function () {
    const { 
      blindBox_minter, blindBox_other, exchange_minter,exchange_buyer,fundManager_buyer,
      settlementToken, address_zero, bytes32_zero,
      blindBox, blindBox_DAO,
      fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    await blindBox_DAO.addToBlacklist(1);
    await blindBox_DAO.addToBlacklist(2);

    // ========================== 购买 失败 ==========================
    await expect(exchange_buyer.buy(1)).to.be.reverted;
    await expect(exchange_buyer.bid(2)).to.be.reverted;
  });

});

