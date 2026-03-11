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

describe("交易测试-常规交易测试", function () {
  // 解构变量，用于单元测试
  

  it("01-minter出售-buyer购买-支付延迟费用- 检查时间-价格-状态", async function () {
    const { 
      admin, dao, minter, buyer, completer,
      settlementToken, 
      truthBox, exchange, fundManager, userManager_buyer,
      DAY, MONTH, YEAR,bytes32_zero,
      exchange_minter,exchange_completer, exchange_buyer, truthBox_buyer, 
      address_zero, userManager_completer ,dao_fund_manager
    } = await loadFixture(deployTruthBoxFixture);

    // 时间增加360天
    await time.increase(MONTH);
    
    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.sell(2, address_zero, 1000);

    // ==========  检查1，2号的deadline是否等于当前时间加365天 ===
    const deadline_01 = Number(await truthBox.getDeadline(1));
    const deadline_02 = Number(await truthBox.getDeadline(2));
    // 获取当前区块时间：当前时间戳/1000+360天
    const now = await time.latest();
    console.log("Swap1-01-当前区块时间:", timestampToDate(now));
    console.log("Swap1-01-deadline_01过期时间:", timestampToDate(deadline_01));
    console.log("Swap1-01-deadline_02过期时间:", timestampToDate(deadline_02)); // 减去当前区块时间后，刚好是365天
    // 使用辅助函数验证时间
    TimeHelpers.verifyDeadline(
      deadline_01,
      now,
      YEAR
    );

    // 使用辅助函数验证时间
    TimeHelpers.verifyDeadline(
      deadline_02,
      now,
      YEAR
    );

    // 检查价格
    expect(await truthBox.getPrice(1)).to.equal(2000);
    expect(await truthBox.getPrice(2)).to.equal(1000);

    // 检查状态是否是1
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Selling);
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Selling);

    // 检查出售者应该为空
    expect(await exchange.sellerIdOf(1)).to.equal(bytes32_zero);
    expect(await exchange.sellerIdOf(2)).to.equal(bytes32_zero);

    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.buy(2);

    // ========================== 检查是否在退款时间内 ==========================
    expect(await exchange.isInRequestRefundDeadline(1)).to.equal(true);
    expect(await exchange.isInRequestRefundDeadline(2)).to.equal(true);

    await time.increase(50 * 24 * 60 * 60);

    expect(await exchange.isInRequestRefundDeadline(1)).to.equal(false);
    expect(await exchange.isInRequestRefundDeadline(2)).to.equal(false);

    // ========================== 时间、状态、价格 ==========================
    
    // 检查1号的状态是否是2
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Paid);
    const deadline_01_2 = Number(await truthBox.getDeadline(1));
    expect(deadline_01_2).to.equal(deadline_01);

    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Paid);

    const deadline_04 = Number(await truthBox.getDeadline(2));
    expect(deadline_04).to.equal(deadline_02);

    // 检查购买者是否是buyer
    const buyer_id = await userManager_buyer.myUserId();
    expect(await exchange.buyerIdOf(1)).to.equal(buyer_id);
    // 检查订单金额是否是2000
    expect(await fundManager.orderAmounts(1, buyer.address)).to.equal(2000);
    
    // ============================== 完成1 ==================================
    await exchange_buyer.completeOrder(1);
    // 检查1号的状态是否是4
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Delaying);

    // 检查1号的
    const orderAmounts_1_buyer = await fundManager.orderAmounts(1, buyer.address);
    expect(orderAmounts_1_buyer).to.equal(0);
    const incomeMinter = await fundManager.rewardAmounts(settlementToken.target,minter.address);
    // 费率为 3% ， 2000*3% = 60
    expect(await settlementToken.balanceOf(dao_fund_manager.address)).to.equal(60);
    expect(incomeMinter).to.equal(1940); // 2000-2000*3%*2
    // expect(blanceOf_daoFund).to.equal(100); // 2000*5%

    // ========================== 完成2 ==========================
    await exchange_completer.completeOrder(2);
    // 检查completer
    const completer_id = await userManager_completer.myUserId();
    expect(await exchange.completerIdOf(2)).to.equal(completer_id);
    const incomeCompleterA = await fundManager.rewardAmounts( settlementToken.target,completer.address);
    const incomeMinter02 = await fundManager.rewardAmounts(settlementToken.target,minter.address);
    console.log("Swap1-01-incomeCompleter02A:", incomeCompleterA);
    console.log("Swap1-01-incomeMinter02:", incomeMinter02);

    // ========================== 缴纳延迟费用 ==========================
    await time.increase(340 * 24 * 60 * 60);
    const price01 = await truthBox.getPrice(1);
    console.log("Swap1-01-price01缴费前:", price01);
    const deadline_05 = Number(await truthBox.getDeadline(1));
    console.log("Swap1-01-deadline_05缴费后:", timestampToDate(deadline_05));
    await truthBox_buyer.delay(1);
    const price02 = await truthBox.getPrice(1);
    console.log("Swap1-01-price02缴费后:", price02);
    const deadline_06 = Number(await truthBox.getDeadline(1));
    console.log("Swap1-01-deadline_06缴费后:", timestampToDate(deadline_06));
    

    // ============================ 一共成交5000，1号2000+2000，2号1000 ===================================
    expect(await settlementToken.balanceOf(dao_fund_manager.address)).to.equal(150);

    expect(await fundManager.rewardAmounts( settlementToken.target,buyer.address)).to.equal(0);

  });

  it("02-minter拍卖-buyer竞拍-检查时间-价格-状态", async function () {
    const { admin, dao, minter, buyer, settlementToken, buyer2, truthBox, exchange, fundManager_buyer ,
      bytes_deliver, userManager_buyer,bytes_mint ,YEAR,MONTH, address_zero, 
      exchange_minter,exchange_DAO,exchange_buyer,exchange_buyer2,userManager_buyer2
    } = await loadFixture(deployTruthBoxFixture);
    
    await exchange_minter.auction(1, address_zero, 2000);
    // 检查1，2号的deadline是否等于当前时间加365天
    const deadline_01 = Number(await truthBox.getDeadline(1));
    // 获取当前区块时间：当前时间戳/1000+360天
    const now = await time.latest();
    console.log("Swap1-当前区块时间:", timestampToDate(now));
    console.log("Swap1-deadline_01过期时间:", timestampToDate(deadline_01));
    // 使用辅助函数验证时间
    TimeHelpers.verifyDeadline(
      deadline_01,
      now,
      MONTH
    );

    // 检查1，2，的价格是否是2000
    expect(await truthBox.getPrice(1)).to.equal(2000);
    // 检查1，2，的状态是否是1
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Auctioning);

    // ========================== 竞拍1 ==========================
    await time.increase(20 * 24 * 60 * 60);

    await exchange_buyer.bid(1);
    // 检查
    const buyerId = await userManager_buyer.myUserId();
    expect(await exchange.buyerIdOf(1)).to.equal(buyerId);
    // 检查时间是否延后
    const deadline_02 = Number(await truthBox.getDeadline(1));
    // 获取当前区块时间：当前时间戳/1000+360天
    const now02 = await time.latest();
    console.log("Swap1-当前区块时间:", timestampToDate(now02));
    console.log("Swap1-deadline_02竞拍1次:", timestampToDate(deadline_02));
    expect(await truthBox.getPrice(1)).to.equal(2200);


    // ========================== 竞拍2 ==========================
    await time.increase(20 * 24 * 60 * 60);

    await exchange_buyer2.bid(1);
    // 检查
    const buyer2_id = await userManager_buyer2.myUserId();
    expect(await exchange.buyerIdOf(1)).to.equal(buyer2_id);
    // 检查 时间是否延后
    const deadline_03 = Number(await truthBox.getDeadline(1));
    // 获取当前区块时间：当前时间戳/1000+360天
    const now03 = await time.latest();
    console.log("Swap1-当前区块时间:", timestampToDate(now03));
    console.log("Swap1-deadline_03竞拍2次:", timestampToDate(deadline_03));
    expect(await truthBox.getPrice(1)).to.equal(2420);


    // ========================== 竞拍3 ==========================
    // buyer第二次竞拍
    await time.increase(20 * 24 * 60 * 60);
    const price = await truthBox.getPrice(1);
    console.log("Swap1-竞拍两次后的价格:", price);
    const payMoney_buyer = await exchange_buyer.calcPayMoney(1)
    console.log("Swap1-buyer第二次竞拍需要支付的资金:", payMoney_buyer);
    await exchange_buyer.bid(1);
    // 检查
    const buyer_id =await userManager_buyer.myUserId();
    expect(await exchange.buyerIdOf(1)).to.equal(buyer_id);

    // ========================== 竞拍4 ==========================
    // other第二次竞拍
    await time.increase(20 * 24 * 60 * 60);
    console.log("Swap1-竞拍三次后的价格:", await truthBox.getPrice(1));
    console.log("Swap1-other第二次竞拍需要支付的资金:", await exchange_buyer2.calcPayMoney(1));
    await exchange_buyer2.bid(1);

    // ==========================  ==========================

    await time.increase(40 * 24 * 60 * 60);

    // 检查1号的状态是否是3
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Paid);
    const deadline_04 = Number(await truthBox.getDeadline(1));
    console.log("Swap1-deadline_04发货后:", timestampToDate(deadline_04));
    // const buyer2_id = await userManager_buyer2.myUserId();
    expect(await exchange.buyerIdOf(1)).to.equal(buyer2_id);

    // ========================== 提款 ============================
    // buyer竞拍失败，提取资金
    console.log("Swap1-buyer提款前的orderAmount:", await fundManager_buyer.orderAmounts(1, buyer.address));
    await fundManager_buyer.withdrawOrderAmounts(settlementToken.target, [1]);
    console.log("Swap1-buyer提款后的orderAmount:", await fundManager_buyer.orderAmounts(1, buyer.address));

    // ========================== 完成 ==========================
    await exchange_buyer2.completeOrder(1);
    // 检查1号的状态是否是Delaying
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Delaying);

  });

  it("03-minter拍卖-竞拍--多种角色提取资金", async function () {
    const { admin, dao, minter, buyer, settlementToken, other, truthBox, 
      exchange_minter, exchange_buyer,exchange_DAO,fundManager_buyer,fundManager_minter,
      dao_fund_manager, fundManager_DAO,fundManager_dao_fund_manager, address_zero,
      fundManager,bytes32_1,bytes_mint ,bytes_deliver} = await loadFixture(deployTruthBoxFixture);

    // deadline增加30天的时间,共计60天，支付服务费
    await exchange_minter.auction(1, address_zero, 1000);

    // ========================== 竞拍1 ==========================
    await time.increase(25 * 24 * 60 * 60);

    await exchange_buyer.bid(1);

    // ========================== 发货 ==========================
    await time.increase(40 * 24 * 60 * 60);
    // 管理员确认，会增加额外费率

    // ========================== 完成 ==========================
    await exchange_buyer.completeOrder(1);
    // 检查1号的状态是否是5
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Delaying);
    // 检查各个账户的收入
    // minter收入 1000-1000*3% = 970
    const incomeMinter = await fundManager.rewardAmounts(settlementToken.target,minter.address);
    expect(incomeMinter).to.equal(970);
    // 费率为 3% ， 1000*3% = 30
    expect(await settlementToken.balanceOf(dao_fund_manager.address)).to.equal(30);

    // 查看合约的余额, 已经支付了50的服务费
    const balancefundManager = await settlementToken.balanceOf(fundManager.target);
    expect(balancefundManager).to.equal(970);

    // ========================== 提取退款 buyer==========================
    // 提款，应该抛出异常
    await expect(fundManager_buyer.withdrawRefundAmounts(settlementToken.target, [1])).to.be.reverted;
    
    // ========================== 提取 minter==========================
    const balanceMinter = await settlementToken.balanceOf(minter.address);
    await fundManager_minter.withdrawRewards(settlementToken.target);
    const balanceMinter02 = await settlementToken.balanceOf(minter.address);
    console.log("Swap1-03-Minter提款了:", balanceMinter02-balanceMinter);
    // 再次提款，应该抛出异常
    await expect(fundManager_minter.withdrawRewards(settlementToken.target)).to.be.reverted;
    // await expect(fundManager_minter.withdrawSeller()).to.be.reverted(exchange,"AmountIsZero");

    // // ========================== 提取 DAO 应该无法提款==========================

    await expect(fundManager_DAO.withdrawRewards(settlementToken.target)).to.be.reverted;

    // ========================== 验证服务费 ==========================
    expect(await settlementToken.balanceOf(dao_fund_manager.address)).to.equal(30);
    // ==================再次提款，应该抛出异常==========
    // 查看合约的余额
    const balancefundManager01 = await settlementToken.balanceOf(fundManager.target);
    console.log("Swap1-03-fundManager合约余额:", balancefundManager01);

  });

});


