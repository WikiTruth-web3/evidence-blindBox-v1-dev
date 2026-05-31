const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployBlindBoxFixture} = require("./fixtures/Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');
const {
  wBTC_amount,
  wETH_amount,
  wROSE_amount,
  settlementToken_amount
} = require("./fixtures/tokenAmount.js");

// npx hardhat test test/contracts-eth/DelayFee.js

describe("BlindBox-DelayFee- 相关测试", async function () {


  it("设置延迟费用率", async function () {
    const { 
      blindBox, fundManager, exchange, blindBox_DAO, blindBox_minter
    } = await loadFixture(deployBlindBoxFixture);

    // 默认费率
    const incrementRate = Number(await blindBox.incrementRate());
    expect(incrementRate).to.equal(200);

    // 设置费率
    await blindBox_DAO.setIncrementRate(150);
    const incrementRate1 = Number(await blindBox.incrementRate());
    expect(incrementRate1).to.equal(150);

    await blindBox_DAO.setIncrementRate(200);
    const incrementRate2 = Number(await blindBox.incrementRate());
    expect(incrementRate2).to.equal(200);
    // 设置大于200的值，应该失败
    await expect(blindBox_DAO.setIncrementRate(201)).to.be.revertedWithCustomError(blindBox,"InvalidRate");

    // 设置0，应该失败
    await expect(blindBox_DAO.setIncrementRate(0)).to.be.revertedWithCustomError(blindBox,"InvalidRate");

    // 非Dao账户设置费率，应该失败
    await expect(blindBox_minter.setIncrementRate(150)).to.be.revertedWithCustomError(blindBox,"NotDAO");
  });  

  

  it("缴纳延迟费用-延长保密时间", async function () {
    const { 
      buyer, 
      blindBox_minter, blindBox_other, exchange_minter,exchange_buyer,exchange_DAO,
      blindBox_buyer, bytes32_1, settlementToken, address_zero, minter, userId_minter,
      blindBox, fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    // =================出售成交================
    await exchange_minter.sell(0, address_zero, settlementToken_amount("20000"));
    // 为`ConfidentialityFee`合约授权代币
    await exchange_buyer.buy(0);

    await exchange_buyer.completeOrder(0);
    
    // 打印buyer账户的代币余额
    const rewards_minter0 = await fundManager.rewardAmounts(userId_minter,settlementToken.target)
    expect (rewards_minter0).to.equal(settlementToken_amount("19400"));
    // =================检查时间================
    const deadline00_0 = Number(await blindBox.getDeadline(0)); 
    const balanceOf_buyer = await settlementToken.balanceOf(buyer.address);
    // =================缴费 1================
    // 调用payFee_合约中的ExtendStoringTime方法
    await time.increase(340*24*60*60);

    await blindBox_buyer.delay(0);
    // 首次支付延迟费用20000
    const balanceOf_buyer1 = await settlementToken.balanceOf(buyer.address);
    expect(balanceOf_buyer - balanceOf_buyer1).to.equal(settlementToken_amount("20000"));

    const deadline00_1 = Number(await blindBox.getDeadline(0)); 
    // 判断是否延长了365天
    expect(deadline00_1).to.equal(deadline00_0 + 365 * 24 * 60 * 60);

    ///
    const rewards_minter = await fundManager.rewardAmounts(userId_minter,settlementToken.target)
    expect (rewards_minter).to.equal(settlementToken_amount("38800"));

    // =================查看价格是否变化===============
    const price_0 = await blindBox_minter.getPrice(0);
    console.log("DelayFee--0缴费之后的价格:",price_0);
    
  });

    it("缴纳延迟费用-未在窗口期无法缴纳", async function () {
    const { 
      buyer, 
      blindBox_minter, blindBox_other, exchange_minter,exchange_buyer,exchange_DAO,
      blindBox_buyer, bytes32_1, settlementToken, address_zero, minter,
      blindBox, fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    // =================出售成交================
    await exchange_minter.sell(0, address_zero, settlementToken_amount("20000"));
    // 为`ConfidentialityFee`合约授权代币
    await exchange_buyer.buy(0);

    await exchange_buyer.completeOrder(0);

    // =================缴费 1================
    // 调用payFee_合约中的ExtendStoringTime方法
    await time.increase(300*24*60*60);
    
    await expect(blindBox_buyer.delay(0)).to.be.revertedWithCustomError(blindBox,"NotInWindowPeriod");

  });


    it("缴纳延迟费用-过期无法缴纳", async function () {
    const { 
      buyer, 
      blindBox_minter, blindBox_other, exchange_minter,exchange_buyer,exchange_DAO,
      blindBox_buyer, bytes32_1, settlementToken, address_zero, minter,
      blindBox, fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    // =================出售成交================
    await exchange_minter.sell(0, address_zero, settlementToken_amount("20000"));
    // 为`ConfidentialityFee`合约授权代币
    await exchange_buyer.buy(0);

    await exchange_buyer.completeOrder(0);

    // =================缴费 1================
    // 调用payFee_合约中的ExtendStoringTime方法
    await time.increase(380*24*60*60);
    
    await expect(blindBox_buyer.delay(0)).to.be.revertedWithCustomError(blindBox,"InvalidStatus");

  });

  it("缴纳延迟费用-加入黑名单-无法缴纳", async function () {
    const { 
      buyer, 
      blindBox_minter, blindBox_DAO, exchange_minter,exchange_buyer,exchange_DAO,
      blindBox_buyer, bytes32_1, settlementToken,address_zero,
      blindBox, fundManager, exchange
    } = await loadFixture(deployBlindBoxFixture);

    // =================出售成交================
    await exchange_minter.sell(0, address_zero, settlementToken_amount("20000"));
    // 为`ConfidentialityFee`合约授权代币
    await exchange_buyer.buy(0);

    await exchange_buyer.completeOrder(0);

    // =================检查时间================
    const deadline00_0 = Number(await blindBox.getDeadline(0)); 
    
    // 加入黑名单
    await blindBox_DAO.addToBlacklist(0);

    // =================缴费 1================
    // 调用payFee_合约中的ExtendStoringTime方法
    await expect(blindBox_buyer.delay(0)).to.be.revertedWithCustomError(blindBox,"InvalidStatus");
    const deadline00_1 = Number(await blindBox.getDeadline(0)); 
    expect(deadline00_1).to.equal(deadline00_0);
  });

});

