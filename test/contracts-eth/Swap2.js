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

describe("交易测试-多角色参与交易过程", function () {

  it("06-过期出售-seller-buyer-completer-提取资金", async function () {
    const { admin, dao, minter, seller, buyer, settlementToken, completer, truthBox, 
      exchange, fundManager ,bytes_mint, bytes_deliver, bytes32_1 , address_zero,
      userManager_completer,
      fundManager_completer,fundManager_DAO,dao_fund_manager, fundManager_dao_fund_manager,
      exchange_seller,exchange_DAO,exchange_buyer,exchange_completer, fundManager_buyer,fundManager_minter,
    } = await loadFixture(deployTruthBoxFixture);

    await time.increase(380 * 24 * 60 * 60);
    // 
    // seller出售 会增加额外费率
    await exchange_seller.sell(1, address_zero, 1000);
    await exchange_seller.auction(2, address_zero, 1000);
    // ========================== 购买 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.bid(2);

    // ========================== 完成 ==========================
    await time.increase(50 * 24 * 60 * 60);
    expect(await exchange.isInRequestRefundDeadline(1)).to.equal(false);
    expect(await exchange.isInRequestRefundDeadline(2)).to.equal(false);
    // completer确认 会增加额外费率
    await exchange_completer.completeOrder(1);
    await exchange_completer.completeOrder(2);
    const completer_id = await userManager_completer.myUserId();
    expect(await exchange.completerIdOf(1)).to.equal(completer_id);
    expect(await exchange.completerIdOf(2)).to.equal(completer_id);

    // ========================== 检查id=1的资金情况 ==========================
    const incomeMinter = await fundManager.rewardAmounts(settlementToken.target,minter.address);
    // const serviceFee = await fundManager.availableServiceFees();

    const incomeCompleter = await fundManager.rewardAmounts(settlementToken.target,completer.address);
    const incomeSeller = await fundManager.rewardAmounts(settlementToken.target,seller.address);
    expect(incomeMinter).to.equal(1900);
    // expect(serviceFee).to.equal(100);

    expect(incomeCompleter).to.equal(20);
    expect(incomeSeller).to.equal(20);
    // NOTE 服务费 3%
    // 查看合约的余额，已支付60服务费
    const balancefundManager = await settlementToken.balanceOf(fundManager.target);
    expect(balancefundManager).to.equal(1940);

    // ========================== 提取 ==========================
    // const balanceBuyer = await settlementToken.balanceOf(buyer.address);
    await expect(fundManager_buyer.withdrawRefundAmounts(settlementToken.target, [1])).to.be.reverted;
    // const balanceBuyer02 = await settlementToken.balanceOf(buyer.address);
    // expect(balanceBuyer02-balanceBuyer).to.equal(750);

    // ========================== 提取2 ==========================
    const balanceMinter = await settlementToken.balanceOf(minter.address);
    await fundManager_minter.withdrawRewards(settlementToken.target);
    const balanceMinter02 = await settlementToken.balanceOf(minter.address);
    expect(balanceMinter02-balanceMinter).to.equal(1900);

    // ========================== 提取3 ==========================
    const fundManagerSeller = fundManager.connect(seller);
    const balanceSeller = await settlementToken.balanceOf(seller.address);
    console.log("Swap2-Seller提款前:", balanceSeller);
    await fundManagerSeller.withdrawRewards(settlementToken.target);
    const balanceSeller02 = await settlementToken.balanceOf(seller.address);
    console.log("Swap2-Seller提款后:", balanceSeller02);

    // ========================== 提取4 ==========================
    const balanceCompleter = await settlementToken.balanceOf(completer.address);
    await fundManager_completer.withdrawRewards(settlementToken.target);
    const balanceCompleter02 = await settlementToken.balanceOf(completer.address);
    expect(balanceCompleter02-balanceCompleter).to.equal(20);

    // ========================== 提取手续费 ==========================
    // await fundManager_DAO.withdrawServiceFee(dao_fund_manager.address);
    const balanceDao_fund_manager1 = await settlementToken.balanceOf(dao_fund_manager.address);
    // 两个box，一共60
    expect(balanceDao_fund_manager1).to.equal(60);

    // const serviceFee02 = await fundManager.availableServiceFees();
    // expect(serviceFee02).to.equal(0);
    // 查看合约的余额
    const balancefundManager01 = await settlementToken.balanceOf(fundManager.target);
    // 资金已经分配完毕
    expect(balancefundManager01).to.equal(0); 

  });

  it("07-黑名单、公开的无法出售", async function () {
    const { minter, truthBox, exchange_minter, settlementToken ,truthBox_DAO,
      truthBox_minter, address_zero,
    } = await loadFixture(deployTruthBoxFixture);
    
    await truthBox_DAO.addToBlacklist(1);
    await truthBox_DAO.addToBlacklist(2);
    // 时间增加360天
    await time.increase(360 * 24 * 60 * 60);
    // 应该抛出异常
    await expect(exchange_minter.sell(1, address_zero, 2000)).to.be.reverted;
    await expect(exchange_minter.sell(2, address_zero, 2000)).to.be.reverted;

  });

  it("08-黑名单、公开的无法拍卖", async function () {
    const { minter, truthBox, exchange, settlementToken ,truthBox_DAO,
      truthBox_minter,exchange_seller, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await truthBox_DAO.addToBlacklist(1);
    // 时间增加360天
    await time.increase(360 * 24 * 60 * 60);
    // 应该抛出异常
    await expect(exchange_seller.auction(1, address_zero,  2000)).to.be.reverted;
    await expect(exchange_seller.auction(2, address_zero, 2000)).to.be.reverted;

  });

  it("09-过期-seller-出售/拍卖", async function () {
    const { 
      minter, buyer, settlementToken, truthBox, exchange_seller, address_zero, seller,
      fundManager, bytes_mint,userManager_seller , exchange_minter,exchange, bytes32_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await time.increase(380 * 24 * 60 * 60);
    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 3000);
    await exchange_seller.sell(3, address_zero, 2000);
    await exchange_seller.auction(4, address_zero, 4000);

    // 检查价格是否被修改
    expect(await truthBox.getPrice(1)).to.equal(2000);
    expect(await truthBox.getPrice(2)).to.equal(3000);
    expect(await truthBox.getPrice(3)).to.equal(1000);
    expect(await truthBox.getPrice(4)).to.equal(1000);
    // 检查1，2，5号的状态是否是1
    expect(await truthBox.getStatus(1)).to.equal(TimeHelpers.Status.Selling);
    expect(await truthBox.getStatus(2)).to.equal(TimeHelpers.Status.Auctioning);
    expect(await truthBox.getStatus(3)).to.equal(TimeHelpers.Status.Selling);
    expect(await truthBox.getStatus(4)).to.equal(TimeHelpers.Status.Auctioning);
    // 检查 seller
    expect(await exchange.sellerIdOf(1)).to.equal(bytes32_zero);
    expect(await exchange.sellerIdOf(2)).to.equal(bytes32_zero);
    const seller_id = await userManager_seller.myUserId();
    expect(await exchange.sellerIdOf(3)).to.equal(seller_id);
    expect(await exchange.sellerIdOf(4)).to.equal(seller_id);

  });

  
});

