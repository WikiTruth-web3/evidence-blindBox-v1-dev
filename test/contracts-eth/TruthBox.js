const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture} = require("./Fixture.js");
const {timestampToDate,secondsToDhms} = require('../utils/timeToDate.js');
const { Status } = require("./helpers.js");


describe("TruthBox合约测试", function () {
  // 基本铸造功能测试
  describe("基本铸造功能", function() {
    it("应该正确铸造TruthBox并获取Box信息", async function () {
      // 测试固件初始化
      const { admin, minter, other, truthBox, bytes_mint, 
        truthBox_minter, truthBox_other, dao} = await loadFixture(deployTruthBoxFixture);
      
      // 再铸造一个新代币 - 
      await truthBox_minter.create("10_tokenURI", "10_infoURI", bytes_mint, 1000);
      
      // 获取并验证Box信息  TODO: 暂时不需要这个函数
      // const boxInfo_0 = await truthBox.getBoxInfoCID(0);
      // expect(boxInfo_0).to.equal("00_infoURI");
      const [status_0, price_0, deadline_0, ] = await truthBox.getBasicData(0);
      expect(status_0).to.equal(Status.Storing);
    });
  });

  // 黑名单功能测试
  describe("黑名单功能", function() {
    it("添加黑名单-获取信息失败", async function () {
      // 测试固件初始化
      const { admin, minter, buyer, other, truthBox, bytes_mint, dao, truthBox_DAO,
        } = await loadFixture(deployTruthBoxFixture);
      
      // 添加到黑名单 - 使用DAO账户
      await truthBox_DAO.addToBlacklist(1);
      expect(await truthBox.isInBlacklist(1)).to.equal(true);
      
      
    });
    
  });

  it("10-黑名单Token--购买/拍卖", async function () {
    const { minter, buyer, truthBox, exchange, fundManager, truthBox_DAO,
      wBTC, bytes32_1 , exchange_minter, exchange_buyer, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 1000);
    await truthBox_DAO.addToBlacklist(1);
    await truthBox_DAO.addToBlacklist(2);
    // ========================== 购买1 ==========================
    // 应该抛出异常
    await expect(exchange_buyer.buy(1)).to.be.reverted;
    // 
    await expect(exchange_buyer.bid(2)).to.be.reverted;
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
        .to.be.revertedWithCustomError(truthBox, "NotMinter");
    });

    it("过期，minter不能延迟deadline", async function () {
      const { truthBox_minter, truthBox ,minter,exchange_minter,exchange_buyer} = await loadFixture(deployTruthBoxFixture);
      // 先获得deadline
      await time.increase(380*24*60*60);
      // 铸造者延迟deadline
      await expect(truthBox_minter.extendDeadline(2, 10000))
        .to.be.revertedWithCustomError(truthBox, "NotInWindowPeriod");
    });

    it("不存在的token-无法延迟deadline", async function () {
      const { 
        truthBox, fundManager, exchange,truthBox_DAO,truthBox_minter,MONTH
      } = await loadFixture(deployTruthBoxFixture);
  
      await expect(truthBox_DAO.extendDeadline(100, MONTH)).to.be.revertedWithCustomError(truthBox,"NotMinter");
      await expect(truthBox_DAO.extendDeadline(100, MONTH)).to.be.revertedWithCustomError(truthBox,"NotMinter");
  
      await expect(truthBox_minter.delay(0)).to.revertedWithCustomError(truthBox,"InvalidStatus");
      await expect(truthBox_minter.delay(1)).to.revertedWithCustomError(truthBox,"InvalidStatus");
  
    });
  });

  // 公开操作测试
  describe("公开操作功能", function() {
    it("minter公开操作", async function () {
      const { truthBox_minter, truthBox ,minter} = await loadFixture(deployTruthBoxFixture);
      
      await truthBox_minter.publishByMinter(2);
      expect(await truthBox.getStatus(2)).to.equal(Status.Published);
    });
    
    it("非minter不能公开操作", async function () {
      const { truthBox } = await loadFixture(deployTruthBoxFixture);
      
      await expect(truthBox.publishByMinter(2))
        .to.be.revertedWithCustomError(truthBox, "NotMinter");
    });
    
      it("出售/拍卖-无buyer---到期自动公开状态--任何人查看机密数据", async function () {
    const { 
      admin, minter, dao, truthBox, wBTC, bytes_mint,
      truthBox_minter, truthBox_DAO, exchange_minter, 
      exchange_buyer, exchange_DAO, fundManager, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    // ========================== 到期自动公开 ==========================
    await time.increase(40*24*60*60);
    
    expect(await truthBox.getStatus(1)).to.equal(Status.Selling);
    expect(await truthBox.getStatus(2)).to.equal(Status.Published);
    // 查看2号
    expect(await truthBox.getSecretData(2)).to.equal(bytes_mint);

    await time.increase(340*24*60*60);
    expect(await truthBox.getStatus(1)).to.equal(Status.Published);
    // 查看1号
    expect(await truthBox.getSecretData(1)).to.equal(bytes_mint);

  });
    
    it("直接调用publicByBuyer --- 失败", async function () {
      const {truthBox, truthBox_buyer} = await loadFixture(deployTruthBoxFixture);
      await expect(truthBox_buyer.publishByBuyer(3)).to.be.revertedWithCustomError(truthBox,"NotBuyer");
      await expect(truthBox.publishByBuyer(1)).to.be.revertedWithCustomError(truthBox,"NotBuyer");
    });

    it("出售/拍卖---minter无法执行公开！", async function () {
    const { 
      admin, minter, dao, buyer, truthBox,wBTC,
      truthBox_minter, truthBox_DAO, exchange_minter, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    // 后移20天
    await time.increase(20*24*60*60);
    expect(await truthBox.getStatus(2)).to.equal(Status.Auctioning);

    // ========================== 公开失败 ==========================
    await expect(truthBox_minter.publishByMinter(2)).to.be.reverted;
    
    await time.increase(160*24*60*60);
    expect(await truthBox.getStatus(1)).to.equal(Status.Selling);
    await expect(truthBox_minter.publishByMinter(2)).to.be.reverted;

  });

  
  // 只测试黑名单功能，其他测试暂时跳过
  it("出售/拍卖---buyer购买---执行公开---过期自动公开", async function () {
    const { 
      admin, minter, dao, truthBox, wBTC,
      truthBox_minter, truthBox_buyer, exchange_minter,
      exchange_buyer, exchange_DAO, fundManager, address_zero,
    } = await loadFixture(deployTruthBoxFixture);

    await exchange_minter.sell(1, address_zero, 2000);
    await exchange_minter.auction(2, address_zero, 2000);

    await exchange_minter.sell(3, address_zero, 2000);
    await exchange_minter.auction(4, address_zero, 2000);

    // ========================== 购买 ==========================
    await exchange_buyer.buy(1)
    await exchange_buyer.bid(2)
    await exchange_buyer.buy(3)
    await exchange_buyer.bid(4)
    await time.increase(80*24*60*60);

    await exchange_buyer.completeOrder(1)
    await exchange_buyer.completeOrder(2)
    await exchange_buyer.completeOrder(3)
    await exchange_buyer.completeOrder(4)

    expect(await truthBox.getStatus(1)).to.equal(Status.Delaying);
    expect(await truthBox.getStatus(2)).to.equal(Status.Delaying);

    // ========================== 执行公开 ==========================
    // minter 无法执行公开操作
    await expect(truthBox_minter.publishByMinter(1)).to.be.reverted;

    await truthBox_buyer.publishByBuyer(1)
    await truthBox_buyer.publishByBuyer(2)
    // 调用PublicNoBuyer函数，传入2号Box
    expect(await truthBox.getStatus(1)).to.equal(Status.Published);
    expect(await truthBox.getStatus(2)).to.equal(Status.Published);

    // ========================== 过期自动公开 ==========================
    await time.increase(380*24*60*60);

    expect(await truthBox.getStatus(3)).to.equal(Status.Published);
    expect(await truthBox.getStatus(4)).to.equal(Status.Published);
  });
  });
});

