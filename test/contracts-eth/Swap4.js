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

describe("交易测试-黑名单相关测试", function () {

  it("13-出售/拍卖-添加黑名单-申请退款失败", async function () {
    const { 
      exchange_minter,exchange_buyer,bytes32_buyer,
      settlementToken, truthBox, truthBox_DAO, address_zero,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    // 将0拉入黑名单，无法出售和拍卖
    await truthBox_DAO.addToBlacklist(0);
    await expect(exchange_minter.sell(0, address_zero, 2000)).to.be.reverted;
    await expect(exchange_minter.auction(0, address_zero, 2000)).to.be.reverted;

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.bid(2);

    // ========================== 发货1 ==========================
    // 将2号加入黑名单
    await truthBox_DAO.addToBlacklist(1);
    await truthBox_DAO.addToBlacklist(2);
    // ========================== 申请退款 ==========================

    // 黑名单 --- 直接获得退款
    await expect(exchange_buyer.requestRefund(1)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(2)).to.be.reverted;
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Blacklisted); // 黑名单 --- 状态不变
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Blacklisted); // 黑名单 --- 状态不变
    expect(await exchange.refundPermit(1)).to.equal(true); // 黑名单 --- 直接获得退款
    expect(await exchange.refundPermit(2)).to.equal(true); // 黑名单 --- 直接获得退款
    // ========================== 尝试再次申请退款 ==========================
    // 已经申请过退款，不能再次申请
    await expect(exchange_buyer.requestRefund(1)).to.be.reverted;
    await expect(exchange_buyer.requestRefund(2)).to.be.reverted;

  });

  it("13-出售/拍卖--申请退款--添加黑名单--后续操作失败", async function () {
    const { 
      exchange_minter,exchange_buyer,bytes32_buyer, exchange_DAO,
      settlementToken, truthBox, truthBox_DAO, address_zero,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

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
    await truthBox_DAO.addToBlacklist(1);
    await truthBox_DAO.addToBlacklist(2);

    await expect(exchange_DAO.agreeRefund(1)).to.be.reverted;
    await expect(exchange_DAO.agreeRefund(2)).to.be.reverted;

    // NOTE 竞拍相关
    await time.increase(30 * 24 * 60 * 60); 
    await exchange_buyer.requestRefund(3);
    await exchange_buyer.requestRefund(4);
    // 加入黑名单
    await truthBox_DAO.addToBlacklist(3);
    await truthBox_DAO.addToBlacklist(4);

    await expect(exchange_DAO.agreeRefund(3)).to.be.reverted;
    await expect(exchange_DAO.agreeRefund(4)).to.be.reverted;

    // ========================== 验证退款 ==========================
        // 黑名单 --- 直接获得退款
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Blacklisted);
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Blacklisted);
    expect(await truthBox.getStatus(3)).to.equal(TimeHelpers.Status.Blacklisted);
    expect(await exchange.refundPermit(3)).to.equal(true); 
    expect(await truthBox.getStatus(4)).to.equal(TimeHelpers.Status.Blacklisted); // 黑名单 ---- 状态不变
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
      truthBox_minter, truthBox_other, exchange_minter,exchange_buyer,truthBox_buyer,
      settlementToken, address_zero, bytes32_zero,
      truthBox, truthBox_DAO,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

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
    await truthBox_DAO.addToBlacklist(1);
    await truthBox_DAO.addToBlacklist(2);
    // ========================== 验证 ==========================
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Blacklisted);
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Blacklisted); 

    // ========================== 尝试再次取消退款 ！！！出错！！！==========================
    // 已经申请过退款，不能再次申请
    await expect(truthBox_buyer.delay(1)).to.be.reverted;
    await expect(truthBox_buyer.delay(2)).to.be.reverted;

    await expect(truthBox_buyer.publishByBuyer(1)).to.be.reverted;
    await expect(truthBox_buyer.publishByBuyer(2)).to.be.reverted;

  });

  it("14-出售/竞拍-添加黑名单-无法购买-提款失败", async function () {
    const { 
      truthBox_minter, truthBox_other, exchange_minter,exchange_buyer,fundManager_buyer,
      settlementToken, address_zero, bytes32_zero,
      truthBox, truthBox_DAO,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    await truthBox_DAO.addToBlacklist(1);
    await truthBox_DAO.addToBlacklist(2);

    // ========================== 购买 失败 ==========================
    await expect(exchange_buyer.buy(1)).to.be.reverted;
    await expect(exchange_buyer.bid(2)).to.be.reverted;

    // 将2和4号加入黑名单
    // ========================== 验证 ==========================
    // 由于没有buyer，所以没有退款许可
    expect(await exchange.refundPermit(1)).to.equal(false);
    expect(await exchange.refundPermit(2)).to.equal(false);
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Blacklisted);
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Blacklisted);

    // ========================== 尝试提款 失败==========================
    // 已经申请过退款，不能再次申请
    await expect(fundManager_buyer.withdrawOrderAmounts(settlementToken.target, [1,2])).to.be.reverted;
    await expect(fundManager_buyer.withdrawRefundAmounts(settlementToken.target, [1,2])).to.be.reverted;

  });

});

