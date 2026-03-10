const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');

describe("TruthBox-DelayFee- 相关测试", async function () {


  it("设置延迟费用率", async function () {
    const { 
      truthBox, fundManager, exchange,truthBox_DAO,truthBox_minter
    } = await loadFixture(deployTruthBoxFixture);

    // 默认费率
    const incrementRate = Number(await truthBox.incrementRate());
    expect(incrementRate).to.equal(200);

    // 设置费率
    await truthBox_DAO.setIncrementRate(150);
    const incrementRate1 = Number(await truthBox.incrementRate());
    expect(incrementRate1).to.equal(150);

    await truthBox_DAO.setIncrementRate(200);
    const incrementRate2 = Number(await truthBox.incrementRate());
    expect(incrementRate2).to.equal(200);
    // 设置大于200的值，应该失败
    await expect(truthBox_DAO.setIncrementRate(201)).to.be.revertedWithCustomError(truthBox,"InvalidRate");

    // 设置0，应该失败
    await expect(truthBox_DAO.setIncrementRate(0)).to.be.revertedWithCustomError(truthBox,"InvalidRate");

    // 非Dao账户设置费率，应该失败
    await expect(truthBox_minter.setIncrementRate(150)).to.be.revertedWithCustomError(truthBox,"NotDAO");
  });  

  

  it("缴纳延迟费用-延长保密时间-过期无法缴纳", async function () {
    const { 
      buyer, 
      truthBox_minter, truthBox_other, exchange_minter,exchange_buyer,exchange_DAO,
      truthBox_buyer, bytes32_1, settlementToken, address_zero, minter,
      truthBox, fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    // =================出售成交================
    await exchange_minter.sell(0, address_zero,20000);
    await exchange_minter.sell(1, address_zero,20000);
    // 为`ConfidentialityFee`合约授权代币
    await exchange_buyer.buy(0);
    await exchange_buyer.buy(1);

    await exchange_buyer.completeOrder(0);
    await exchange_buyer.completeOrder(1);
    
    // 打印buyer账户的代币余额
    const balanceOf_buyer = await settlementToken.balanceOf(buyer.address);
    console.log("DelayFee--feeToken_buyer缴费之前余额:",balanceOf_buyer.toString());
    ///
    const rewards_minter0 = await fundManager.rewardAmounts(settlementToken.target,minter.address)
    expect (rewards_minter0).to.equal(38800)
    // =================检查时间================
    const deadline01_0 = Number(await truthBox.getDeadline(1)); 
    const deadline00_0 = Number(await truthBox.getDeadline(0)); 
    // =================缴费 1================
    // 调用payFee_合约中的ExtendStoringTime方法
    await time.increase(340*24*60*60);
    
    await truthBox_buyer.delay(0);
    await truthBox_buyer.delay(1);
    const deadline00_1 = Number(await truthBox.getDeadline(0)); 
    const deadline01_1 = Number(await truthBox.getDeadline(1)); 

    // 判断是否延长了365天
    expect(deadline00_1).to.equal(deadline00_0 + 365 * 24 * 60 * 60);
    expect(deadline01_1).to.equal(deadline01_0 + 365 * 24 * 60 * 60);

    // 打印buyer账户的代币余额
    const balanceOf_buyer1 = await settlementToken.balanceOf(buyer.address);
    console.log("DelayFee--feeToken_buyer缴费之后余额——1:",balanceOf_buyer1.toString());
    expect(Number(balanceOf_buyer)-Number(balanceOf_buyer1)).to.equal(40000)
    ///
    const rewards_minter = await fundManager.rewardAmounts(settlementToken.target,minter.address)
    expect (rewards_minter).to.equal(77600)

    // =================查看价格是否变化===============
    const price_0 = await truthBox_minter.getPrice(0);
    const price_1 = await truthBox_minter.getPrice(1);
    console.log("DelayFee--0缴费之后的价格:",price_0);
    console.log("DelayFee--1缴费之后的价格:",price_1);
    // =================缴费 2================
    // 只缴费一个
    await time.increase(365 * 24 * 60 * 60);
    await truthBox_buyer.delay(0);
    const deadline00_2 = Number(await truthBox.getDeadline(0)); 
    const deadline01_2 = Number(await truthBox.getDeadline(1)); 
    // 只有0号box延长了365天
    expect(deadline00_2).to.equal(deadline00_1 + 365 * 24 * 60 * 60);
    expect(deadline01_2).to.equal(deadline01_1);

    // 打印buyer账户的代币余额
    const balanceOf_buyer2 = await settlementToken.balanceOf(buyer.address);
    console.log("buyer缴费之后余额——1:",balanceOf_buyer2.toString());
    // 验证刚才缴费是否有40000
    expect(Number(balanceOf_buyer1)-Number(balanceOf_buyer2)).to.equal(40000)
    ///
    const rewards_minter2 = await fundManager.rewardAmounts(settlementToken.target,minter.address)
    expect (rewards_minter2).to.equal(116400)

    // =================缴费 3================
    
    await time.increase(365 * 24 * 60 * 60);
    await truthBox_buyer.delay(0);
    
    // 时间延迟365天，过期后就无法再进行延期了
    await expect(truthBox_buyer.delay(1)).to.be.revertedWithCustomError(truthBox,"NotInWindowPeriod");

    // 打印buyer账户的代币余额
    const balanceOf_buyer3 = await settlementToken.balanceOf(buyer.address);
    console.log("buyer缴费之后余额——2:",balanceOf_buyer3.toString());
    // 验证刚才缴费是否有80000
    expect(Number(balanceOf_buyer2)-Number(balanceOf_buyer3)).to.equal(80000)
    // 检查minter的收入
    const rewards_minter3 = await fundManager.rewardAmounts(settlementToken.target,minter.address)
    expect (rewards_minter3).to.equal(194000)

    const price_0_2 = await truthBox_minter.getPrice(0);
    console.log("DelayFee--0缴费之后的价格:",price_0_2);

  });

  it("缴纳延迟费用-加入黑名单-无法缴纳", async function () {
    const { 
      buyer, 
      truthBox_minter, truthBox_DAO, exchange_minter,exchange_buyer,exchange_DAO,
      truthBox_buyer, bytes32_1, settlementToken,address_zero,
      truthBox, fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    // =================出售成交================
    await exchange_minter.sell(0, address_zero,20000);
    // 为`ConfidentialityFee`合约授权代币
    await exchange_buyer.buy(0);

    await exchange_buyer.completeOrder(0);

    // =================检查时间================
    const deadline00_0 = Number(await truthBox.getDeadline(0)); 
    
    // 加入黑名单
    await truthBox_DAO.addToBlacklist(0);

    // =================缴费 1================
    // 调用payFee_合约中的ExtendStoringTime方法
    await expect(truthBox_buyer.delay(0)).to.be.revertedWithCustomError(truthBox,"InvalidStatus");
    const deadline00_1 = Number(await truthBox.getDeadline(0)); 
    expect(deadline00_1).to.equal(deadline00_0);
  });

});

