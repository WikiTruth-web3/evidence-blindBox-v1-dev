const { ethers } = require("hardhat");
const {
  decimals_settlementToken,
  decimals_wBTC,
  decimals_wETH,
  decimals_wROSE
} = require("./decimals.js");

function wBTC_amount(str) {
  return ethers.parseUnits(str.toString(), decimals_wBTC);
}

function wETH_amount(str) {
  return ethers.parseUnits(str.toString(), decimals_wETH);
}

function wROSE_amount(str) {
  return ethers.parseUnits(str.toString(), decimals_wROSE);
}

function settlementToken_amount(str) {
  return ethers.parseUnits(str.toString(), decimals_settlementToken);
}

module.exports = {
  wBTC_amount,
  wETH_amount,
  wROSE_amount,
  settlementToken_amount
};