const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const crypto = require('crypto'); // 引入crypto库 nodejs内置的加密库
const {timestampToDate,secondsToDhms} = require('../utils/timeToDate.js');

// 测试直接调用Exchange合约中的相关函数
describe("Exchange", function () {

  it("查询-Dao设置期限-成功", async function () {
    const { 
      exchange_DAO,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);
    
    const refundReviewPeriod = secondsToDhms(Number(await exchange.refundReviewPeriod()));
    const refundRequestPeriod = secondsToDhms(Number(await exchange.refundRequestPeriod()));
    console.log("Exchange--30天", refundReviewPeriod);
    console.log("Exchange--15天", refundRequestPeriod);
    
    // 调用setConfirmDeadline设置期限函数，传入20天
    await exchange_DAO.setRefundRequestPeriod(10*24*60*60);
    expect(await exchange.refundRequestPeriod()).to.equal(10*24*60*60);
    await exchange_DAO.setRefundReviewPeriod(30*24*60*60);
    expect(await exchange.refundReviewPeriod()).to.equal(30*24*60*60);

    // ===========================Dao 设置期限=====================
    await exchange_DAO.setRefundRequestPeriod(15*24*60*60);
    expect(await exchange.refundRequestPeriod()).to.equal(15*24*60*60);
    await exchange_DAO.setRefundReviewPeriod(50*24*60*60);
    expect(await exchange.refundReviewPeriod()).to.equal(50*24*60*60);

  });

  it("设置期限-失败", async function () {
    const {exchange_DAO, exchange, exchange_minter} = await loadFixture(deployTruthBoxFixture);
    
    // ==========================期限值不正确=========================
    await expect(exchange_DAO.setRefundRequestPeriod(3*24*60*60)).to.be.revertedWithCustomError(exchange,"InvalidPeriod");
    await expect(exchange_DAO.setRefundRequestPeriod(20*24*60*60)).to.be.revertedWithCustomError(exchange,"InvalidPeriod");
    await expect(exchange_DAO.setRefundReviewPeriod(10*24*60*60)).to.be.revertedWithCustomError(exchange,"InvalidPeriod");
    await expect(exchange_DAO.setRefundReviewPeriod(70*24*60*60)).to.be.revertedWithCustomError(exchange,"InvalidPeriod");
    
    // ==========================caller不正确=========================
    await expect(exchange_minter.setRefundRequestPeriod(15*24*60*60)).to.be.revertedWithCustomError(exchange_minter,"NotDAO");
    await expect(exchange_minter.setRefundReviewPeriod(50*24*60*60)).to.be.revertedWithCustomError(exchange_minter,"NotDAO");

  });

  // 直接设置退款许可 --- 失败
  it("直接设置退款许可 --- 失败", async function () {
    const {exchange_minter, exchange} = await loadFixture(deployTruthBoxFixture);
    await expect(exchange.setRefundPermit(3, true)).to.be.revertedWithCustomError(exchange,"InvalidCaller");
    await expect(exchange.setRefundPermit(1, true)).to.be.revertedWithCustomError(exchange,"InvalidCaller");
    
  });

  // it("验证大额交易-调整费率", async function () { 
  //   const { 
  //     truthBox, exchange_minter, exchange_buyer, exchange_buyer2, exchange_other,
  //     officialToken, exchange_DAO, truthBox_DAO, fundManager_DAO,buyer, truthBox_buyer,
  //     bytes32_buyer, fundManager, exchange,buyer2,fundManager_buyer2,fundManager_buyer
  //   } = await loadFixture(deployTruthBoxFixture);

  //   // 调整费率
  //   await exchange_DAO.setBidIncrementRate(150);
  //   await truthBox_DAO.setIncrementRate(150);

  //   // 拍卖成交，
  //   await exchange_minter.auction(1,  20000000000000000);
  //   // await exchange_buyer2.bid(1);
  //   await exchange_buyer.bid(1);

  //   await time.increase(35*24*60*60);
  //   await exchange_buyer.completeOrder(1);

  //   // 验证价格是否为3000
  //   expect (await truthBox.getPrice(1)).to.equal(3000);
    
  //   // 缴纳保密费
  //   const balance_buyer_1 = await officialToken.balanceOf(buyer.address)
  //   await truthBox_buyer.payConfiFee(1);
  //   const balance_buyer_2 = await officialToken.balanceOf(buyer.address)

  //   expect(balance_buyer_1-balance_buyer_2).to.equal(3000);
  //   await truthBox_buyer.payConfiFee(1);
  //   const balance_buyer_3 = await officialToken.balanceOf(buyer.address)
  //   expect(balance_buyer_2-balance_buyer_3).to.equal(4500);

  // });


});

