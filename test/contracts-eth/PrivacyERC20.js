const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployBlindBoxFixture } = require("./fixtures/Fixture.js");
const exp = require("constants");
const { timestampToDate, secondsToDhms } = require('../utils/timeToDate.js');
const TimeHelpers = require("./helpers");

const {
  wBTC_amount,
  wETH_amount,
  wROSE_amount,
  settlementToken_amount
} = require("./fixtures/tokenAmount.js");
// npx hardhat test test/contracts-eth/PrivacyERC20.js 

describe("交易测试-多角色参与交易过程", function () {

  it("1-使用PrivacyERC20代币出售-buyer-completer-提取资金", async function () {
    const { admin, dao, minter, seller, buyer,settlementToken, settlementToken_Privacy, completer, blindBox, 
      exchange, fundManager ,bytes_mint, bytes_deliver, bytes32_1 , address_zero,
      userManager_completer,userId_completer, userId_minter, userId_seller, userId_buyer,
      fundManager_completer,fundManager_DAO,dao_treasury, fundManager_dao_treasury,
      exchange_seller, exchange_minter ,exchange_DAO,exchange_buyer,exchange_completer, fundManager_buyer,fundManager_minter,
    } = await loadFixture(deployBlindBoxFixture);

    await time.increase(380 * 24 * 60 * 60);
    // 
    // seller出售 会增加额外费率
    await exchange_minter.sell(1, settlementToken_Privacy.target, settlementToken_amount("2000"));
    await exchange_seller.auction(2, settlementToken_Privacy.target, settlementToken_amount("2000"));
    // ========================== 购买 ==========================
    await exchange_buyer.buy(1);
    await exchange_buyer.bid(2);
    const payBuyer_1 = await fundManager.orderAmounts(1,userId_buyer);
    expect(payBuyer_1).to.equal(settlementToken_amount("2000"));

    const payBuyer_2 = await fundManager.orderAmounts(2,userId_buyer);
    expect(payBuyer_2).to.equal(settlementToken_amount("1000"));

    // ========================== 完成 ==========================
    await time.increase(50 * 24 * 60 * 60);
    // completer确认 会增加额外费率
    await exchange_completer.completeOrder(1);
    await exchange_completer.completeOrder(2);

    // ========================== 检查id=1的资金情况 ==========================
    const incomeMinter = await fundManager.rewardAmounts(userId_minter, settlementToken_Privacy.target);
    expect(incomeMinter).to.equal(settlementToken_amount("1920"));

    // seller ---- settlementToken
    const incomeMinter_2 = await fundManager.rewardAmounts(userId_minter, settlementToken.target);
    expect(incomeMinter_2).to.equal(settlementToken_amount("950"));

    const incomeCompleter = await fundManager.rewardAmounts(userId_completer, settlementToken.target);
    const incomeSeller = await fundManager.rewardAmounts(userId_seller, settlementToken.target);

    expect(incomeCompleter).to.equal(settlementToken_amount("110")); // 20*5+10
    expect(incomeSeller).to.equal(settlementToken_amount("10"));
    // NOTE 服务费 3%
    // 查看合约的余额，已支付60服务费
    const balancefundManager = await settlementToken_Privacy.balanceOf(fundManager.target);
    expect(balancefundManager).to.equal(settlementToken_amount("1920")); // minter are not withdraw yet

    // ========================== 提取2 ==========================
    const balanceMinter = await settlementToken_Privacy.balanceOf(minter.address);
    await fundManager_minter.withdrawRewards(settlementToken_Privacy.target, minter.address);
    const balanceMinter02 = await settlementToken_Privacy.balanceOf(minter.address);
    expect(balanceMinter02-balanceMinter).to.equal(settlementToken_amount("1920"));

    const balancefundManager01 = await settlementToken_Privacy.balanceOf(fundManager.target);
    expect(balancefundManager01).to.equal(settlementToken_amount("0")); 

    // ========================== 提取手续费 ==========================
    // await fundManager_DAO.withdrawServiceFee(dao_treasury.address);
    const balanceDao_treasury1 = await settlementToken_Privacy.balanceOf(dao_treasury.address);
    // 两个box，一共60
    expect(balanceDao_treasury1).to.equal(settlementToken_amount("80"));


  });

  
});

