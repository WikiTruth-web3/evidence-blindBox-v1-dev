const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate,secondsToDhms} = require('../utils/timeToDate.js');

describe("FundManager", function () {

  it("切换提款许可---只有admin可以切换", async function () {
    const { 
      admin, fundManager_DAO, dao, minter, fundManager_minter,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    // 切换为true
    await fundManager.pause();
    expect(await fundManager.paused()).to.equal(true);
    await fundManager.unpause();
    expect(await fundManager.paused()).to.equal(false);

    // ==============================其他人调用失败===============================
    // 调用togglePauseWithdraw函数，应该抛出异常
    await expect(fundManager_minter.pause()).to.be.reverted;
    // 调用togglePauseWithdraw函数，应该抛出异常
    await expect(fundManager_DAO.unpause()).to.be.reverted;

  });

  it("切换提款许可---提款", async function () {
    const { 

      truthBox_minter, truthBox_buyer, exchange_minter,exchange_buyer,
      bytes32_1, bytes32_2, fundManager_minter, wBTC, settlementToken, address_zero,
      fundManager, exchange
    } = await loadFixture(deployTruthBoxFixture);

    // ===========================mint =========================
    await exchange_minter.sell(0, address_zero, 2000);
    await exchange_buyer.buy(0);
    await exchange_buyer.completeOrder(0);

    // 切换为true(即已暂停)
    await fundManager.pause();
    expect(await fundManager.paused()).to.equal(true);
    // ===========================提款失败！ =========================
    await expect(fundManager_minter.withdrawRewards(settlementToken.target)).to.reverted;

    // 切换为false(即已恢复)
    await fundManager.unpause();
    expect(await fundManager.paused()).to.equal(false);

    // ===========================提款成功！ =========================
    await fundManager_minter.withdrawRewards(settlementToken.target);

  });

  // 设置滑点-成功
  // it("设置滑点-成功", async function () {
  //   const {admin, fundManager} = await loadFixture(deployTruthBoxFixture);
  //   await fundManager.setSlippageProtection(10);
  //   expect(await fundManager.slippageProtection()).to.equal(10);
  // });

  // 设置滑点-失败
  // it("设置滑点-失败", async function () {
  //   const {admin, fundManager} = await loadFixture(deployTruthBoxFixture);
  //   await expect(fundManager.setSlippageProtection(101)).to.be.reverted;
  //   await expect(fundManager.setSlippageProtection(0)).to.be.reverted;
  // });

  it("直接--接收orderAmount-失败", async function () {
    const {admin, minter, fundManager,wBTC} = await loadFixture(deployTruthBoxFixture);

    const fundMinter = await fundManager.connect(minter);
    // 调用接收服务费函数，传入1000个代币
    await expect(fundMinter.payOrderAmount(1, minter.address,1000)).to.be.reverted;
    
  });

  it("接收延迟费用-失败-不能直接调用", async function () {
    const {admin, minter, seller, buyer, fundManager,wBTC} = await loadFixture(deployTruthBoxFixture);
    // 调用接收服务费函数，传入1000个代币
    await expect(fundManager.payDelayFee(1, buyer.address, 1000)).to.be.reverted;
    // 检查
    // expect(await fundManager.totalRewardAmounts(wBTC.target)).to.equal(1000);
    // expect(await fundManager.availableServiceFees()).to.equal(50);
    // const minterRewardAmounts = await fundManager.minterRewardAmounts(wBTC.target,1);
    // console.log("FundManager--minterRewardAmounts:", minterRewardAmounts.toString());

  });

  it("直接--allocationRewards-失败", async function () {
    const {fundManager} = await loadFixture(deployTruthBoxFixture);
    // 调用feeToken合约mint函数，给minter地址发送10000个代币
    await expect(fundManager.allocationRewards(1)).to.be.reverted;
    
  });


  it("查询-为空", async function () {
    const {minter, fundManager, seller, wBTC, userManager} = await loadFixture(deployTruthBoxFixture);
    // const orderAmount = await fundManager.orderAmount(1, minter.address);
    // 检查orderMoney是否为空
    expect(await fundManager.orderAmounts(1, minter.address)).to.equal(0);
    await expect(fundManager.rewardAmounts(wBTC.target,seller.address)).to.be.revertedWithCustomError(userManager,"EmptyUserId")

  });

  // 1,测试非buyer能否提取withdrawRefundAmounts

  it("非buyer提取退款-失败", async function () {
    const { 
      truthBox_minter, exchange_minter, exchange_buyer, fundManager_buyer,fundManager_completer,
      bytes32_buyer, bytes_deliver, fundManager, exchange,fundManager_minter,wBTC, 
      settlementToken,
      address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    // 准备测试环境：出售、购买、发货、请求退款
    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_buyer.buy(1);
    await exchange_buyer.requestRefund(1);
    await exchange_minter.agreeRefund(1);
    
    // 验证买家是否拥有退款许可
    expect(await exchange.refundPermit(1)).to.equal(true);
    
    // 非买家（这里用卖家和其他账户）尝试提取退款，应该失败
    await expect(fundManager_minter.withdrawOrderAmounts(settlementToken.target, [1]))
      .to.be.reverted;
      
    await expect(fundManager_completer.withdrawOrderAmounts(settlementToken.target, [1]))
      .to.be.reverted;
      
    // 真正的买家应该可以成功提取退款
    await fundManager_buyer.withdrawRefundAmounts(settlementToken.target, [1]);
    
    // 再次尝试提取应该失败，因为金额已经被提取
    await expect(fundManager_buyer.withdrawOrderAmounts(settlementToken.target, [1]))
      .to.be.reverted;
  });

  // 2,测试非minter能否提取minterRewardAmounts

  it("非minter提取奖励-失败", async function () {
    const { 
      truthBox_minter, exchange_minter, exchange_buyer, exchange_other,
      bytes32_buyer, bytes_deliver, fundManager, fundManager_buyer,
      wBTC, address_zero, settlementToken,
      truthBox,minter,fundManager_completer,fundManager_minter,
    } = await loadFixture(deployTruthBoxFixture);

    // 准备测试环境：出售、购买、完成交易
    await exchange_minter.sell(2, address_zero, 2000);
    await exchange_buyer.buy(2);
    await exchange_buyer.completeOrder(2);
    
    // 非铸造者（这里用买家和其他账户）尝试提取铸造者奖励，应该失败
    await expect(fundManager_buyer.withdrawRewards(settlementToken.target))
      .to.be.revertedWithCustomError(fundManager, "AmountIsZero");
      
    await expect(fundManager_completer.withdrawRewards(settlementToken.target))
      .to.be.revertedWithCustomError(fundManager, "AmountIsZero");
      
    // 真正的铸造者应该可以成功提取奖励
    await fundManager_minter.withdrawRewards(settlementToken.target);
    
    // 再次尝试提取应该失败，因为金额已经被提取
    await expect(fundManager_minter.withdrawRewards(settlementToken.target))
      .to.be.revertedWithCustomError(fundManager, "AmountIsZero");
  });

  // 3,测试buyer能否提取withdrawOrderAmounts

  it("buyer提取订单金额-失败", async function () {
    const { 
      truthBox_minter, exchange_minter, exchange_buyer, exchange_buyer2, exchange_other,
      wBTC, address_zero, settlementToken, 
      userManager, userManager_buyer2,
      fundManager, exchange,buyer2,fundManager_buyer2,fundManager_buyer
    } = await loadFixture(deployTruthBoxFixture);

    // 准备测试环境：出售并竞拍，但未最终购买
    await exchange_minter.auction(3, address_zero, 2000);
    
    // 多个账户竞拍
    await exchange_buyer.bid(3);
    await exchange_buyer2.bid(3);

    const buyerId_2 = await userManager_buyer2.myUserId();
    
    // 验证当前买家是其他账户（最后一个竞拍者）
    expect(await exchange.buyerIdOf(3)).to.equal(buyerId_2);
    
    // 当前买家尝试提取订单金额，应该失败
    await expect(fundManager_buyer2.withdrawOrderAmounts(settlementToken.target, [3]))
      .to.be.revertedWithCustomError(fundManager, "InvalidCaller");
      
    // 已经被取代的前一个竞拍者可以提取他们的订单金额
    await fundManager_buyer.withdrawOrderAmounts(settlementToken.target, [3]);
    
    // 创建一个新的拍卖
    await exchange_minter.auction(4, address_zero, 3000);
    
    // 买家竞拍但还未被取代
    await exchange_buyer.bid(4);
    
    // 买家尝试提取自己的订单金额，应该失败
    await expect(fundManager_buyer.withdrawOrderAmounts(settlementToken.target, [4]))
      .to.be.revertedWithCustomError(fundManager, "InvalidCaller");
    
    // 不是竞拍者的账户应该也无法提取（金额为0）
    await expect(fundManager_buyer2.withdrawOrderAmounts(settlementToken.target, [4]))
      .to.be.revertedWithCustomError(fundManager, "AmountIsZero");
  });

  it("测试调整费率-交易的资金", async function () { 
    const { 
      truthBox, exchange_minter, exchange_buyer, exchange_buyer2, exchange_other,
      settlementToken, exchange_DAO, truthBox_DAO, fundManager_DAO,buyer, truthBox_buyer,
      bytes32_buyer, fundManager, exchange,buyer2,fundManager_buyer2,fundManager_buyer,
      address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    // 调整费率
    await exchange_DAO.setBidIncrementRate(150);
    await truthBox_DAO.setIncrementRate(150);

    // 拍卖成交，
    await exchange_minter.auction(1, address_zero, 2000);
    // await exchange_buyer2.bid(1);
    await exchange_buyer.bid(1);

    await time.increase(35*24*60*60);
    await exchange_buyer.completeOrder(1);

    // 验证价格是否为3000
    expect (await truthBox.getPrice(1)).to.equal(3000);
    
    // 缴纳延迟费用
    await time.increase(340*24*60*60);
    const balance_buyer_1 = await settlementToken.balanceOf(buyer.address)
    await truthBox_buyer.delay(1);
    const balance_buyer_2 = await settlementToken.balanceOf(buyer.address)

    await time.increase(365*24*60*60);
    expect(balance_buyer_1-balance_buyer_2).to.equal(3000);
    await truthBox_buyer.delay(1);
    const balance_buyer_3 = await settlementToken.balanceOf(buyer.address)
    expect(balance_buyer_2-balance_buyer_3).to.equal(4500);

  });

});

