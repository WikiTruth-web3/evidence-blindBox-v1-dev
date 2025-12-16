const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate,secondsToDhms} = require('../utils/timeToDate.js');
const { Status } = require("./helpers.js");

/**
 * 测试合约：TruthBox.sol
 * 主要测试内容：
 * 1. 基本铸造功能
 * 2. 黑名单功能
 * 3. 代币转移功能
 * 4. 延迟deadline
 * 5. 公开操作功能
 */

describe("TruthBox合约测试", function () {
  // 基本铸造功能测试
  describe("基本铸造功能", function() {
    it("应该正确铸造TruthBox并获取Box信息", async function () {
      // 测试固件初始化
      const { admin, minter, other, truthBox, truthNFT, bytes_mint, 
        truthBox_minter, truthBox_other, dao} = await loadFixture(deployTruthBoxFixture);
      
      // Fixture中已经铸造了5个代币, 验证初始状态
      // 使用truthNFT而不是truthBox检查代币所有权
      expect(await truthNFT.ownerOf(0)).to.equal(minter.address);
      expect(await truthNFT.ownerOf(1)).to.equal(minter.address);
      
      // 再铸造一个新代币 - 注意mint函数只接受三个参数
      await truthBox_minter.create(minter.address, "10_tokenURI", "10_infoURI", bytes_mint, 1000);
      
      // 获取并验证Box信息  TODO: 暂时不需要这个函数
      // const boxInfo_0 = await truthBox.getBoxInfoCID(0);
      // expect(boxInfo_0).to.equal("00_infoURI");
      const [status_0, price_0, deadline_0, ] = await truthBox.getBasicData(0);
      const tokenURI_0 = await truthNFT.tokenURI(0);
      expect(tokenURI_0).to.equal('ipfs://00_tokenURIfleek.app');
      // expect(infoURI_0).to.equal("00_infoURI");
      expect(status_0).to.equal(Status.Storing);
    });
  });

  // 黑名单功能测试
  describe("黑名单功能", function() {
    it("添加黑名单-获取信息失败", async function () {
      // 测试固件初始化
      const { admin, minter, buyer, other, truthBox, truthNFT, bytes_mint, dao, truthBox_DAO,
        nft_DAO} = await loadFixture(deployTruthBoxFixture);
      
      // 添加到黑名单 - 使用DAO账户
      await truthBox_DAO.addBoxToBlacklist(1);
      expect(await truthBox.isInBlacklist(1)).to.equal(true);
      
      // 黑名单中的代币不应该能够获取信息
      await expect(truthNFT.tokenURI(1))
        .to.be.revertedWithCustomError(truthNFT, "InBlacklist");
      
    });
    
    it("黑名单中的代币不应该能执行其他操作-转移", async function () {
      const { truthBox, truthNFT, truthBox_minter, nft_DAO, minter,truthBox_DAO } = await loadFixture(deployTruthBoxFixture);
      
      // 添加到黑名单 - 使用DAO账户
      await truthBox_DAO.addBoxToBlacklist(1);
      
      // 黑名单中的代币不应能批准转移
      await expect(truthNFT.connect(minter).approve(truthBox.target, 1))
        .to.be.revertedWithCustomError(truthNFT, "InvalidStatus");
    });
  });

  it("10-黑名单Token--购买/拍卖", async function () {
    const { minter, buyer, nft_DAO, truthBox, exchange, fundManager, truthBox_DAO,
      testToken, bytes32_1 , exchange_minter, exchange_buyer, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 1000);
    await truthBox_DAO.addBoxToBlacklist(1);
    await truthBox_DAO.addBoxToBlacklist(2);
    // ========================== 购买1 ==========================
    // 应该抛出异常
    await expect(exchange_buyer.buy(1)).to.be.reverted;
    // 
    await expect(exchange_buyer.bid(2)).to.be.reverted;
  });

  // 代币转移测试
  describe("代币转移功能", function() {
    it("完成交易后才能能正确转移代币所有权", async function () {
      const { admin, minter, other, exchange_minter, truthNFT, 
        truthBox_minter,exchange_buyer, address_zero 
      } = await loadFixture(deployTruthBoxFixture);
      // 完成交易
      await exchange_minter.sell(2, address_zero, 2000);
      await exchange_buyer.buy(2);
      await exchange_buyer.completeOrder(2);

      // 授权并转移代币
      await truthNFT.connect(minter).approve(other.address, 2);
      await truthNFT.connect(other).transferFrom(minter.address, admin.address, 2);
      
      // 验证所有权变更
      expect(await truthNFT.ownerOf(2)).to.equal(admin.address);
    });
    
    it("未完成交易不应该能转移代币所有权", async function () {
      const { buyer, truthBox, truthNFT, truthBox_DAO, nft_DAO, minter } = await loadFixture(deployTruthBoxFixture);
      
      // 添加到黑名单 - 使用DAO账户
      await truthBox_DAO.addBoxToBlacklist(1);
      
      // 尝试授权黑名单中的代币
      await expect(truthNFT.connect(minter).approve(buyer.address, 1))
        .to.be.revertedWithCustomError(truthNFT, "InvalidStatus");
    });
  });

  // 延迟deadline
  describe("延迟deadline", function() {
    it("未过期，minter可以延迟deadline", async function () {
      const { truthBox_minter, truthBox ,minter,exchange_minter,truthBox_buyer} = await loadFixture(deployTruthBoxFixture);
      // 先获得deadline
      const deadline = Number(await truthBox.getDeadline(2));
      // 铸造者延迟deadline
      await time.increase(340*24*60*60)
      await truthBox_minter.extendDeadline(2, 10000);
      const newDeadline = Number(await truthBox.getDeadline(2));
      // 验证deadline是否延长
      expect(newDeadline).to.equal(deadline + 10000);

      // 非minter不能延迟deadline
      await expect(truthBox_buyer.extendDeadline(2, 10000))
        .to.be.revertedWithCustomError(truthBox, "InvalidCaller");
    });

    it("过期，minter不能延迟deadline", async function () {
      const { truthBox_minter, truthBox ,minter,exchange_minter,exchange_buyer} = await loadFixture(deployTruthBoxFixture);
      // 先获得deadline
      await time.increase(380*24*60*60);
      // 铸造者延迟deadline
      await expect(truthBox_minter.extendDeadline(2, 10000))
        .to.be.revertedWithCustomError(truthBox, "DeadlineNotIn30days");
    });

    it("不存在的token-无法延迟deadline", async function () {
      const { 
        truthBox, fundManager, exchange,truthBox_DAO,truthBox_minter,MONTH
      } = await loadFixture(deployTruthBoxFixture);
  
      await expect(truthBox_DAO.extendDeadline(100, MONTH)).to.be.revertedWithCustomError(truthBox,"InvalidBoxId");
      await expect(truthBox_DAO.extendDeadline(100, MONTH)).to.revertedWithCustomError(truthBox,"InvalidBoxId");
  
      await expect(truthBox_minter.payConfiFee(0)).to.revertedWithCustomError(truthBox,"InvalidStatus");
      await expect(truthBox_minter.payConfiFee(1)).to.revertedWithCustomError(truthBox,"InvalidStatus");
  
    });
  });

  // 公开操作测试
  describe("公开操作功能", function() {
    it("铸造者应该能在任何时候公开代币内容", async function () {
      const { truthBox_minter, truthBox ,minter} = await loadFixture(deployTruthBoxFixture);
      
      // 铸造者公开代币 - 仅测试函数调用，不验证状态
      await truthBox_minter.publishByMinter(2);
      expect(await truthBox.getStatus(2)).to.equal(Status.Published);
    });
    
    // 由于当前存在合约实现问题，暂时跳过这些测试
    it("非铸造者不应该能公开代币内容", async function () {
      const { truthBox } = await loadFixture(deployTruthBoxFixture);
      
      // 非铸造者尝试公开
      await expect(truthBox.publishByMinter(2))
        .to.be.revertedWithCustomError(truthBox, "InvalidCaller");
    });
    
    it("出售/拍卖-如果无人购买应该直接变成公开状态", async function () {
      const { 
        truthBox_minter, exchange_minter, truthBox_DAO, address_zero,
        truthBox_other, truthBox, testToken
      } = await loadFixture(deployTruthBoxFixture);
      
      // 设置为出售和拍卖状态
      await exchange_minter.sell(1, address_zero, 2000);
      await exchange_minter.auction(3, address_zero, 3000);
      
      // 推进时间模拟超过拍卖/出售期
      await time.increase(380 * 24 * 60 * 60);
      
      // 验证公开状态
      expect(await truthBox.getStatus(1)).to.equal(Status.Published);
      expect(await truthBox.getStatus(3)).to.equal(Status.Published);
    });
    
    it("如果未出售/拍卖，非minter则不能公开", async function () {
      const { truthBox, truthBox_minter } = await loadFixture(deployTruthBoxFixture);
      
      // 非minter仍不能公开
      await expect(truthBox.publishByMinter(2))
        .to.be.revertedWithCustomError(truthBox, "InvalidCaller");
    });

    // 直接调用PublicByBuyer  --- 失败
    it("直接调用publicByBuyer --- 失败", async function () {
      const {truthBox, truthBox_buyer} = await loadFixture(deployTruthBoxFixture);
      await expect(truthBox_buyer.publishByBuyer(3)).to.be.revertedWithCustomError(truthBox,"NotBuyer");
      await expect(truthBox.publishByBuyer(1)).to.be.revertedWithCustomError(truthBox,"NotBuyer");
    });
  });
});

