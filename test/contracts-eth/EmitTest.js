const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture } = require("./Fixture.js");
const { FundsType, RewardType, Status } = require("./helpers");

// npx hardhat test test/contracts-eth/EmitTest.js

describe("Exchange 交易流程事件测试", function () {
  it("00-mint: minter 铸造 TruthBox 事件", async function () {
    const {
      exchange_minter,
      exchange_seller,
      exchange,
      truthBox,
      truthBox_minter,
      address_zero,
      bytes_mint,
      settlementToken,
      wBTC
    } = await loadFixture(deployTruthBoxFixture);

    const tx = await truthBox_minter.create("test_boxInfoCID_",bytes_mint,5000)
    await expect(tx)
      .and.to.emit(truthBox, "PriceChanged")
      .withArgs(6, 5000)
      .and.to.emit(truthBox, "BoxCreated")
      .withArgs(6, anyValue, "test_boxInfoCID_")
      .and.to.emit(truthBox, "DeadlineChanged")
      .withArgs(6, anyValue);
  });

  it("01-sell+auction: minter 上架触发 Exchange + TruthBox 事件", async function () {
    const {
      exchange_minter,
      exchange_seller,
      exchange,
      truthBox,
      address_zero,
      settlementToken,
      wBTC
    } = await loadFixture(deployTruthBoxFixture);

    const tx = exchange_minter.sell(1, address_zero, 2000);

    await expect(tx)
      .to.emit(exchange, "BoxListed")
      .withArgs(1, anyValue, settlementToken.target)
      .and.to.emit(truthBox, "PriceChanged")
      .withArgs(1, 2000)
      .and.to.emit(truthBox, "BoxStatusChanged")
      .withArgs(1, Status.Selling)
      .and.to.emit(truthBox, "DeadlineChanged")
      .withArgs(1, anyValue);

    // 使用wBTC作为支付代币
    const tx2 = exchange_minter.auction(2, wBTC.target, 5000);
    await expect(tx2)
      .to.emit(exchange, "BoxListed")
      .withArgs(2, anyValue, wBTC.target)
      .and.to.emit(truthBox, "PriceChanged")
      .withArgs(2, 5000)
      .and.to.emit(truthBox, "BoxStatusChanged")
      .withArgs(2, Status.Auctioning)
      .and.to.emit(truthBox, "DeadlineChanged")
      .withArgs(2, anyValue);
  });

  it("02-sell+auction: seller 上架触发 Exchange + TruthBox 事件", async function () {
      const {
        exchange_minter,
        exchange_seller,
        exchange,
        truthBox,
        address_zero,
        settlementToken,
        wBTC
      } = await loadFixture(deployTruthBoxFixture);
    await time.increase(380 * 24 * 60 * 60);

    const tx3 = exchange_seller.sell(1, settlementToken.target, 2000);
    await expect(tx3)
      .to.emit(exchange, "BoxListed")
      .withArgs(1, anyValue, settlementToken.target)
      .and.to.emit(truthBox, "BoxStatusChanged")
      .withArgs(1, Status.Selling)
      .and.to.emit(truthBox, "DeadlineChanged")

      const tx4 = exchange_seller.auction(2, wBTC.target, 3000);
      await expect(tx4)
        .to.emit(exchange, "BoxListed")
        .withArgs(2, anyValue, settlementToken.target) // 代币不会被改动
        // .and.to.emit(truthBox, "PriceChanged")
        // .withArgs(2, 2000) // 价格不会被改动
        .and.to.emit(truthBox, "BoxStatusChanged")
        .withArgs(2, Status.Auctioning)
        .and.to.emit(truthBox, "DeadlineChanged")
        .withArgs(2, anyValue);
  });

  it("02-buy: 购买触发状态变化 + 购买 + 退款截止时间事件", async function () {
    const {
      exchange_minter,
      exchange_buyer,
      exchange,
      truthBox,
      address_zero,
      fundManager,
      settlementToken,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);

    const tx = exchange_buyer.buy(1);

    await expect(tx)
      .to.emit(truthBox, "BoxStatusChanged")
      .withArgs(1, Status.Paid)
      .and.to.emit(exchange, "RequestDeadlineChanged")
      .withArgs(1, anyValue)
      .and.to.emit(exchange, "BoxPurchased")
      .withArgs(1, anyValue)
      .and.to.emit(fundManager, "OrderAmountPaid")
      .withArgs(1, anyValue, settlementToken.target, 2000);


  });

  it("03- bid: 竞拍触发出价、价格、截止时间事件、支付资金， 竞拍失败后，提取order资金", async function () {
    const {
      exchange_minter,
      exchange_seller,
      exchange_buyer,
      exchange_buyer2,
      fundManager,
      fundManager_buyer,
      exchange,
      truthBox,
      address_zero,
      wBTC,
      settlementToken,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.auction(1, address_zero, 5000);
    await time.increase(1 * 24 * 60 * 60);

    const tx = exchange_buyer.bid(1);

    await expect(tx)
      .to.emit(exchange, "RequestDeadlineChanged")
      .withArgs(1, anyValue)
      .and.to.emit(truthBox, "PriceChanged")
      .withArgs(1, 5500)
      .and.to.emit(truthBox, "DeadlineChanged")
      .withArgs(1, anyValue)
      .and.to.emit(exchange, "BidPlaced")
      .withArgs(1, anyValue)
      .and.to.emit(fundManager, "OrderAmountPaid")
      .withArgs(1, anyValue, settlementToken.target, 5000);

    // buyer2 参与竞拍，buyer提取资金
    const tx2 = exchange_buyer2.bid(1);

    const tx3 = fundManager_buyer.withdrawOrderAmounts(settlementToken.target, [1]);
    await expect(tx3)
      .to.emit(fundManager, "OrderAmountWithdraw")
      .withArgs([1], settlementToken.target, anyValue, 5000, FundsType.Order);


  });

  it("04-refund 流程: requestRefund + agreeRefund 触发对应事件", async function () {
    const {
      exchange_minter,
      exchange_buyer,
      fundManager,
      fundManager_buyer,
      exchange,
      truthBox,
      address_zero,
      settlementToken,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_buyer.buy(1);

    const requestTx = exchange_buyer.requestRefund(1);
    await expect(requestTx)
      .to.emit(truthBox, "BoxStatusChanged")
      .withArgs(1, Status.Refunding)
      .and.to.emit(exchange, "ReviewDeadlineChanged")
      .withArgs(1, anyValue);

    const agreeTx = exchange_minter.agreeRefund(1);
    await expect(agreeTx)
      .to.emit(truthBox, "BoxStatusChanged")
      .withArgs(1, Status.Published)
      .and.to.emit(exchange, "RefundPermitChanged")
      .withArgs(1, true);

    // buyer 提取退款
    const withdrawTx = fundManager_buyer.withdrawRefundAmounts(settlementToken.target, [1]);
    await expect(withdrawTx)
      .to.emit(fundManager, "OrderAmountWithdraw")
      .withArgs([1], settlementToken.target, anyValue, 2000, FundsType.Refund);

  });

  it("05-completeOrder: 非买家完成订单触发 CompleterAssigned + 状态变更", async function () {
    const {
      exchange_minter,
      exchange_buyer,
      exchange_completer,
      exchange,
      truthBox,
      fundManager,
      fundManager_completer,
      fundManager_minter,
      settlementToken,
      address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_buyer.buy(1);
    await time.increase(50 * 24 * 60 * 60);

    const tx = exchange_completer.completeOrder(1);
    await expect(tx)
      .to.emit(exchange, "CompleterAssigned")
      .withArgs(1, anyValue)
      .and.to.emit(truthBox, "BoxStatusChanged")
      .withArgs(1, Status.Delaying)
      .and.to.emit(fundManager, "RewardsAdded")
      .withArgs(1, settlementToken.target, 2000, RewardType.Total);

    // completer 提取奖励
    const withdrawTx = fundManager_completer.withdrawRewards(settlementToken.target);
    await expect(withdrawTx)
      .to.emit(fundManager, "RewardsWithdraw")
      .withArgs(anyValue, settlementToken.target, anyValue);

    // minter 提取奖励
    const withdrawTx2 = fundManager_minter.withdrawRewards(settlementToken.target);
    await expect(withdrawTx2)
      .to.emit(fundManager, "RewardsWithdraw")
      .withArgs(anyValue, settlementToken.target, anyValue);
  });

  it("06-completeOrder: 非买家完成订单, 非settlementToken支付, ", async function () {
    const {
      exchange_minter,
      exchange_buyer,
      exchange_completer,
      exchange,
      truthBox,
      fundManager,
      fundManager_completer,
      fundManager_minter,
      settlementToken,
      address_zero,
      wBTC,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, wBTC, 2000); // NOTE 这里是wBTC
    await exchange_buyer.buy(1);
    await time.increase(50 * 24 * 60 * 60);

    const tx = exchange_completer.completeOrder(1);
    await expect(tx)
      .to.emit(exchange, "CompleterAssigned")
      .withArgs(1, anyValue)
      .and.to.emit(truthBox, "BoxStatusChanged")
      .withArgs(1, Status.Delaying)
      .and.to.emit(fundManager, "RewardsAdded")
      .withArgs(1, wBTC.target, 2000, RewardType.Total);

    // completer 提取奖励
    const withdrawTx = fundManager_completer.withdrawRewards(settlementToken.target);
    await expect(withdrawTx)
      .to.emit(fundManager, "RewardsWithdraw")
      .withArgs(anyValue, settlementToken.target, anyValue);

    // minter 提取奖励
    const withdrawTx2 = fundManager_minter.withdrawRewards(wBTC.target);
    await expect(withdrawTx2)
      .to.emit(fundManager, "RewardsWithdraw")
      .withArgs(anyValue, wBTC.target, anyValue);
  });
});


