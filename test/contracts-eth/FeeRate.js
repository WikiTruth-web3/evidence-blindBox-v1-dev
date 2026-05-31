const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployBlindBoxFixture} = require("./fixtures/Fixture.js");
const {
  wBTC_amount,
  wETH_amount,
  wROSE_amount,
  settlementToken_amount
} = require("./fixtures/tokenAmount.js");

// npx hardhat test test/contracts-eth/FeeRate.js 

describe("FundManager_FeeRate", function () {

  it("dao设置费率---成功", async function () {
    const { 
      admin, admin2, dao, minter, seller, buyer, completer, other, other2,
      fundManager_DAO,blindBox_DAO,blindBox_minter, exchange_DAO, exchange_minter,
      fundManager, exchange, dao_treasury,
    } = await loadFixture(deployBlindBoxFixture);
    
    await fundManager_DAO.setServiceFeeRate(10);
    await exchange_DAO.setBidIncrementRate(101);
    await fundManager_DAO.setHelperFeeRate(5);
    // 检查延迟费用率是否等于
    expect(await fundManager.helperFeeRate()).to.equal(5);
    expect(await fundManager.serviceFeeRate()).to.equal(10);
    expect(await exchange_minter.bidIncrementRate()).to.equal(101);

    // ==============================非DAO 设置 失败=================================
    const feeRateMinter = await fundManager.connect(minter);
    // 调用设置延迟费用率函数，应该抛出异常
    await expect(feeRateMinter.setServiceFeeRate(10)).to.be.revertedWithCustomError(fundManager,"NotDAO");
    await expect(exchange_minter.setBidIncrementRate(101)).to.be.revertedWithCustomError(exchange_minter,"NotDAO");
    await expect(feeRateMinter.setHelperFeeRate(5)).to.be.revertedWithCustomError(fundManager,"NotDAO");

    // =======================再次检查===========================
    expect(await fundManager.helperFeeRate()).to.equal(5);
    expect(await fundManager.serviceFeeRate()).to.equal(10);
    expect(await exchange_minter.bidIncrementRate()).to.equal(101);
  }); 

  it("检查费用是否正确", async function () {
    const { 
      admin, dao, minter, buyer, settlementToken, completer,
      blindBox, exchange, fundManager, 
      DAY, MONTH, YEAR,
      exchange_minter,exchange_DAO, exchange_buyer, blindBox_buyer, exchange_completer,
      address_zero,dao_treasury,userManager_buyer, userManager_completer,
      userId_minter, userId_buyer, userId_completer
    } = await loadFixture(deployBlindBoxFixture);

    // 时间增加360天
    await time.increase(MONTH);
    
    await exchange_minter.sell(1, address_zero, settlementToken_amount("2000"));
    await exchange_minter.sell(2, address_zero, settlementToken_amount("1000"));

    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.buy(2);

    await time.increase(50 * 24 * 60 * 60);

    // ============================== 完成1 ==================================
    await exchange_buyer.completeOrder(1);

    // 检查1号的订单金额

    const orderAmounts_1_buyer = await fundManager.orderAmounts(1, userId_buyer);
    expect(orderAmounts_1_buyer).to.equal(0);
    // 检查1号的minter收入
    const incomeMinter = await fundManager.rewardAmounts(userId_minter, settlementToken.target);
    expect(incomeMinter).to.equal(settlementToken_amount("1920")); // 2000-2000*3%*2 = 1940
    // 检查1号的DAO收入（服务费）
    expect(await settlementToken.balanceOf(dao_treasury.address)).to.equal(settlementToken_amount("60"));

    // ========================== 完成2 ==========================
    await exchange_completer.completeOrder(2);
    expect(await fundManager.rewardAmounts(userId_buyer, settlementToken.target)).to.equal(settlementToken_amount("20"));
    // 检查completer
    const completerId =await userManager_completer.myUserId();
    expect(await exchange.completerIdOf(2)).to.equal(completerId);
    const incomeCompleterA = await fundManager.rewardAmounts(userId_completer, settlementToken.target);
    const incomeMinter02 = await fundManager.rewardAmounts(userId_minter, settlementToken.target);
    expect(incomeCompleterA).to.equal(settlementToken_amount("10"));
    expect(incomeMinter02).to.equal(settlementToken_amount("2880"));

    // ========================== 缴纳延迟费用 ==========================
    await expect(blindBox_buyer.delay(1)).to.be.revertedWithCustomError(blindBox,"NotInWindowPeriod");
    // 必须在距离deadline的30天之内
    await time.increase(340 * 24 * 60 * 60);

    const price01 = await blindBox.getPrice(1);
    expect(price01).to.equal(settlementToken_amount("2000")); 
    await blindBox_buyer.delay(1); // 缴费后，价格变为4000，收取服务费2000*5%=100
    const price02 = await blindBox.getPrice(1);
    expect(price02).to.equal(settlementToken_amount("4000"));
    

    // ============================ 一共成交5000，1号2000+2000，2号1000 ===================================
    // 费率为 3% ， 1000*3% = 30*5=150
    expect(await settlementToken.balanceOf(dao_treasury.address)).to.equal(settlementToken_amount("150"));


  });

  
});

