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

describe("交易合约测试-SwapContract", function () {

  it("16- 基本功能测试", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_buyer2, buyer, buyer2, bytes32_buyer, wBTC,
      settlementToken, truthBox, truthBox_DAO, address_zero, minter, dao_fund_manager, admin,
      fundManager, exchange,fundManager_buyer2,fundManager_buyer, fundManager_minter,
      swapContract, swapContract_minter, swapContract_buyer, swapContract_other,
    } = await loadFixture(deployTruthBoxFixture);

    const amountIn = await swapContract_minter.getSwapAmountIn(wBTC.target, settlementToken.target, 10000);
    console.log("amountIn:", amountIn);

    const liquidity0 = await swapContract_minter.liquidity(wBTC.target);
    console.log("liquidity:", liquidity0);

    const liquidity1 = await swapContract_minter.liquidity(settlementToken.target);
    console.log("liquidity:", liquidity1);

    const liquidity = await swapContract_minter.liquidity(admin.address);
    console.log("admin liquidity:", liquidity);

  });

  it("16- 交易测试-swapExact-getSwapAmountOut", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_buyer2, buyer, buyer2, bytes32_buyer, wBTC,
      settlementToken, truthBox, truthBox_DAO, address_zero, minter, dao_fund_manager,
      fundManager, exchange,fundManager_buyer2,fundManager_buyer, fundManager_minter,
      swapContract, swapContract_minter, swapContract_buyer, swapContract_other,
    } = await loadFixture(deployTruthBoxFixture);

    console.log("-----------------输入10000 个officialToken-----------------");

    const token_1_balance = Number(await settlementToken.balanceOf(minter.address));
    console.log("交易前token_1余额:", token_1_balance);
    const token_2_balance = Number(await wBTC.balanceOf(minter.address));
    console.log("交易前tokenOut余额:", token_2_balance);

    const amountOut = await swapContract_minter.getSwapAmountOut(settlementToken.target, wBTC.target, 10000);
    console.log("amountOut预测值（获得的testToken数量）:", amountOut);

    await swapContract_minter.swapExact(settlementToken.target, wBTC.target, 10000);

    const token_1_balance_after = Number(await settlementToken.balanceOf(minter.address));
    console.log("交易后token_1余额:", token_1_balance_after);
    const token_2_balance_after = Number(await wBTC.balanceOf(minter.address));
    console.log("交易后tokenOut余额:", token_2_balance_after);

    expect(token_1_balance_after).to.equal(token_1_balance - 10000);

    console.log("本次交易获得testToken数量:", token_2_balance_after - token_2_balance);
    // 测试预测值是否正确
    expect(amountOut).to.equal(token_2_balance_after - token_2_balance);

  })

  it("16- 交易测试-swapForExact-getSwapAmountIn", async function () {
    const { 
      exchange_minter,exchange_buyer, exchange_buyer2, buyer, buyer2, bytes32_buyer, wBTC,
      settlementToken, truthBox, truthBox_DAO, address_zero, minter, dao_fund_manager,
      fundManager, exchange,fundManager_buyer2,fundManager_buyer, fundManager_minter,
      swapContract, swapContract_minter, swapContract_buyer, swapContract_other,
    } = await loadFixture(deployTruthBoxFixture);

    console.log("-----------------需要输出10000 个officialToken-----------------");

    const token_1_balance = Number(await settlementToken.balanceOf(minter.address));
    console.log("交易前token_1余额:", token_1_balance);
    const token_2_balance = Number(await wBTC.balanceOf(minter.address));
    console.log("交易前tokenOut余额:", token_2_balance);

    const amountIn = await swapContract_minter.getSwapAmountIn(wBTC.target, settlementToken.target, 10000);
    console.log("amountIn预测值（消耗的testToken数量）:", amountIn);

    await swapContract_minter.swapForExact(wBTC.target, settlementToken.target, 10000);

    const token_1_balance_after = Number(await settlementToken.balanceOf(minter.address));
    console.log("交易后token_1余额:", token_1_balance_after);
    const token_2_balance_after = Number(await wBTC.balanceOf(minter.address));
    console.log("交易后tokenOut余额:", token_2_balance_after);

    expect(token_1_balance_after).to.equal(token_1_balance + 10000);

    console.log("本次交易消耗testToken数量:", token_2_balance - token_2_balance_after);
    // 测试预测值是否正确
    expect(amountIn).to.equal(token_2_balance - token_2_balance_after);

  })




});

