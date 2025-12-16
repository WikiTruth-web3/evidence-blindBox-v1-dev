const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');
/**
 * 测试合约：UserId.sol
 * 主要测试内容：
 * 1. 获取用户ID
 * 2. 加入黑名单
 * 3. 获取黑名单状态
 */

describe("UserId- 相关测试", function () {
  it("获取用户ID", async function () {
    const { 
      truthBox, exchange, fundManager, userId,
      buyer, minter, dao,
      userId_buyer, userId_minter, userId_DAO
    } = await loadFixture(deployTruthBoxFixture);

    // 首先通过truthBox.getUserIdByAddress()为用户分配ID
    await truthBox.getUserId(buyer.address);
    await truthBox.getUserId(minter.address);
    await truthBox.getUserId(dao.address);

    // 现在检查myUserId()返回的值
    const id_buyer = await userId_buyer.myUserId();
    const id_minter = await userId_minter.myUserId();
    const id_DAO = await userId_DAO.myUserId();

    // 验证ID不为0（表示已分配）
    expect(id_buyer).to.be.greaterThan(0);
    expect(id_minter).to.be.greaterThan(0);
    expect(id_DAO).to.be.greaterThan(0);


    // 验证不同用户有不同的ID
    expect(id_buyer).to.not.equal(id_minter);
    expect(id_buyer).to.not.equal(id_DAO);
    expect(id_minter).to.not.equal(id_DAO);

    // 加入黑名单
    await userId.addBlacklist(buyer.address);
    expect(await userId.isBlacklisted(buyer.address)).to.equal(true);

    await expect(userId_buyer.myUserId()).to.be.revertedWithCustomError(userId, "Blacklisted");

    await userId.removeBlacklist(buyer.address);
    expect(await userId.isBlacklisted(buyer.address)).to.equal(false);
    expect(await userId_buyer.myUserId()).to.equal(id_buyer);

  });  


});

