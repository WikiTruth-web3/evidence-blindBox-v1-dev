const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate} = require('../utils/timeToDate.js');

describe("UserManager- 相关测试", function () {
  it("获取用户ID", async function () {
    const { 
      truthBox, exchange, fundManager, userManager,
      buyer, minter, dao,
      userManager_buyer, userManager_minter, userManager_DAO
    } = await loadFixture(deployTruthBoxFixture);

    // 现在检查myUserId()返回的值
    const id_minter = await userManager_minter.myUserId();

    // 验证ID不为0（表示已分配）
    expect(id_minter).to.equal(10000);

    // 加入黑名单
    await userManager.addBlacklist(buyer.address);
    expect(await userManager.isBlacklisted(buyer.address)).to.equal(true);

    await expect(userManager_buyer.myUserId()).to.be.revertedWithCustomError(userManager, "InBlacklist");

    await userManager.removeBlacklist(buyer.address);
    expect(await userManager.isBlacklisted(buyer.address)).to.equal(false);

  });  


});

