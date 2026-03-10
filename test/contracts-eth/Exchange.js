const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
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
    await expect(exchange.setRefundPermit(3, true)).to.be.revertedWithCustomError(exchange,"NotProjectCaller");
    await expect(exchange.setRefundPermit(1, true)).to.be.revertedWithCustomError(exchange,"NotProjectCaller");
    
  });


});

