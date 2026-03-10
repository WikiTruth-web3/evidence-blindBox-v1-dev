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

describe("交易测试-多代币测试", function () {

  it("15- minter 使用testToken出售", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_buyer2, buyer, buyer2, bytes32_buyer, wBTC,
      settlementToken, truthBox, truthBox_DAO, address_zero, minter, dao_fund_manager,
      fundManager, exchange,fundManager_buyer2,fundManager_buyer, fundManager_minter,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, wBTC.target, 2000);
    await exchange_minter.auction(2, wBTC.target, 2000);
    // ========================== 购买1 ==========================
    await exchange_buyer.buy(1); // 2000*5% = 100
    await exchange_buyer2.bid(2);

    await time.increase(25*24*60*60)
    await exchange_buyer.bid(2); // 2200*5% = 110

    await time.increase(35*24*60*60)

    // ========================== 完成 ==========================

    await exchange_buyer.completeOrder(1);
    await exchange_buyer.completeOrder(2);

    const tx1 = await wBTC.balanceOf(buyer.address);
    const tx2 = await wBTC.balanceOf(buyer2.address);

    console.log("buyer的余额：", tx1);
    console.log("buyer2的余额：", tx2);

    // ========================== 检查收入 ==========================

    // TODO 
    // 在Fixture中，设置officialToken与testToken的兑换比例为10:1，
    // 所以：原本按比例收取210的testToken，兑换后获得2092（被滑点和手续费扣除后的）的officialToken
    const balanceDao_fund_manager1 = await settlementToken.balanceOf(dao_fund_manager.address);
    console.log("Swap5-01-balanceDao_fund_manager1:", balanceDao_fund_manager1);
    const incomeMinter = await fundManager.rewardAmounts(wBTC.target,minter.address);
    console.log("Swap5-01-incomeMinter:", incomeMinter);

    // ========================== 提取 ==========================

    await fundManager_buyer2.withdrawOrderAmounts(wBTC.target, [2])
    expect(fundManager_buyer.withdrawOrderAmounts(wBTC.target, [2])).to.be.reverted;

    await fundManager_minter.withdrawRewards(wBTC.target)

  });

  it("15- seller 使用testToken出售", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_buyer2, buyer, buyer2, bytes32_buyer, wBTC,
      settlementToken, truthBox, truthBox_DAO, address_zero, minter, dao_fund_manager,
      fundManager, exchange, exchange_seller, fundManager_buyer2,fundManager_buyer, fundManager_minter,
    } = await loadFixture(deployTruthBoxFixture);

    await time.increase(380*24*60*60)
    await exchange_seller.sell(1, wBTC.target, 2000);
    await exchange_seller.auction(2, wBTC.target, 2000);

    expect(await exchange.acceptedToken(1)).to.equal(settlementToken.target)
    expect(await exchange.acceptedToken(2)).to.equal(settlementToken.target)

    await exchange_buyer.buy(1);
    await exchange_buyer.bid(2);

    await time.increase(35*24*60*60)

    // ========================== 完成 ==========================

    await exchange_buyer.completeOrder(1);
    await exchange_buyer.completeOrder(2);

    const tx1 = await settlementToken.balanceOf(buyer.address);
    const tx2 = await settlementToken.balanceOf(buyer2.address);

    console.log("buyer的余额：", tx1);
    console.log("buyer2的余额：", tx2);


  })



});

