const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { deployBlindBoxFixture } = require("./fixtures/Fixture.js");
const { settlementToken_amount } = require("./fixtures/tokenAmount.js");

describe("Forwarder 元交易测试", function () {
  
  // 辅助函数：为 Forwarder 构造并签署元交易请求
  async function signForwardRequest(signer, forwarder, targetAddress, data, deadline, value = 0n, gas = 1000000n) {
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const nonce = await forwarder.nonces(signer.address);

    const domain = {
      name: "Hardhat test forwarder",
      version: "1",
      chainId: chainId,
      verifyingContract: forwarder.target
    };

    const types = {
      ForwardRequest: [
        { name: "from", type: "address" },
        { name: "to", type: "address" },
        { name: "value", type: "uint256" },
        { name: "gas", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint48" },
        { name: "data", type: "bytes" }
      ]
    };

    const message = {
      from: signer.address,
      to: targetAddress,
      value: value,
      gas: gas,
      nonce: nonce,
      deadline: deadline,
      data: data
    };

    const signature = await signer.signTypedData(domain, types, message);

    return {
      ...message,
      signature: signature
    };
  }

  it("目标合约不在白名单中 -- 转发失败", async function () {
    const { forwarder, other, blindBox, bytes_mint } = await loadFixture(deployBlindBoxFixture);

    // 此时 blindBox 没有加入白名单
    const data = blindBox.interface.encodeFunctionData("create", [
      "not_whitelisted_uri",
      bytes_mint,
      settlementToken_amount("1000")
    ]);

    const deadline = Math.floor(Date.now() / 1000) + 3600;
    
    // 构造任意的签名请求，这里用 other 签名
    const request = await signForwardRequest(other, forwarder, blindBox.target, data, deadline);

    // 默认 forwarder 应该拦截由于 to 不在白名单
    await expect(forwarder.connect(other).execute(request))
      .to.be.revertedWithCustomError(forwarder, "NotWhitelistedTarget");
  });

  it("Relayer 被拉入黑名单 -- 转发失败", async function () {
    const { forwarder, other, userManager_DAO, blindBox, bytes_mint } = await loadFixture(deployBlindBoxFixture);

    // 1. 将 blindBox 加入白名单
    await forwarder.setTargetStatus(blindBox.target, true);

    // 2. 将 other (Relayer) 加入黑名单
    await userManager_DAO.addBlacklist(other.address);

    // 确认 other 确实被加入了黑名单
    expect(await userManager_DAO.isBlacklisted(other.address)).to.equal(true);

    const data = blindBox.interface.encodeFunctionData("create", [
      "blacklist_relayer_uri",
      bytes_mint,
      settlementToken_amount("1000")
    ]);
    const deadline = Math.floor(Date.now() / 1000) + 3600;

    // 构造请求，由部署人 admin 签名
    const [admin] = await ethers.getSigners();
    const request = await signForwardRequest(admin, forwarder, blindBox.target, data, deadline);

    // 由黑名单中的 other 执行，应该抛出 RelayerIsBlacklisted 错误
    await expect(forwarder.connect(other).execute(request))
      .to.be.revertedWithCustomError(forwarder, "RelayerIsBlacklisted");
  });

  it("签名过期 -- 转发失败", async function () {
    const { forwarder, other, blindBox, bytes_mint } = await loadFixture(deployBlindBoxFixture);

    // 1. 将 blindBox 加入白名单
    await forwarder.setTargetStatus(blindBox.target, true);

    const data = blindBox.interface.encodeFunctionData("create", [
      "expired_uri",
      bytes_mint,
      settlementToken_amount("1000")
    ]);

    // 2. 构造一个已经过期的 deadline（10秒前过期）
    const currentBlockTime = await time.latest();
    const deadline = currentBlockTime - 10;

    // 3. 签名
    const request = await signForwardRequest(other, forwarder, blindBox.target, data, deadline);

    // 4. 执行转发，应当失败
    await expect(forwarder.connect(other).execute(request))
      .to.be.revertedWithCustomError(forwarder, "ERC2771ForwarderExpiredRequest");
  });

  it("正常流程：委托 Minter 发布 BlindBox 并验证 msgSender 恢复", async function () {
    const { forwarder, other, minter, blindBox, bytes_mint, userId_minter } = await loadFixture(deployBlindBoxFixture);

    // 1. 将 blindBox 加入白名单
    await forwarder.setTargetStatus(blindBox.target, true);

    // 2. 准备委托发布盲盒的 calldata
    const testUri = "forwarder_success_uri";
    const price = settlementToken_amount("1500");
    const data = blindBox.interface.encodeFunctionData("create", [
      testUri,
      bytes_mint,
      price
    ]);

    // 3. 构造请求与签名（由 minter 签名）
    const deadline = (await time.latest()) + 3600;
    const request = await signForwardRequest(minter, forwarder, blindBox.target, data, deadline);

    // 4. 记录新创建的项目ID是否为 6
    const nextBoxId = 6n; // 前面创建了0, 1, 2, 3, 4，而 5 是 createAndPublish，所以下一个是 6

    // 5. Relayer (other) 调用 forwarder.execute 转发执行
    await expect(forwarder.connect(other).execute(request))
      .to.emit(forwarder, "ExecutedForwardRequest")
      .withArgs(minter.address, 0n, true);

    // 6. 验证盲盒状态和真正的 minter 是否被识别为 minter，而不是 other (relayer)
    expect(await blindBox.minterIdOf(nextBoxId)).to.equal(userId_minter);
    expect(await blindBox.getPrice(nextBoxId)).to.equal(price);
    
    // 验证状态是否为 Storing (0)
    expect(await blindBox.getStatus(nextBoxId)).to.equal(0); // Storing
  });

  it("正常流程：委托 Buyer 购买盲盒（验证真实的 buyerId 记录为 buyer）", async function () {
    const { forwarder, other, buyer, exchange, exchange_buyer, exchange_minter, settlementToken, address_zero, userManager, userId_buyer } = await loadFixture(deployBlindBoxFixture);

    // 1. 将 exchange 加入白名单
    await forwarder.setTargetStatus(exchange.target, true);

    // 2. 准备盲盒项目：出售盲盒 0 
    const price = settlementToken_amount("2000");
    await exchange_minter.sell(0, address_zero, price);

    // 3. 买家对 settlementToken 进行授权以允许 Exchange 扣除资金
    await settlementToken.connect(buyer).approve(exchange.target, price);

    // 4. 准备买家委托购买 blindBox 0 的 calldata
    const data = exchange.interface.encodeFunctionData("buy", [0n]);

    // 5. 构造请求与签名（由 buyer 签名）
    const deadline = (await time.latest()) + 3600;
    const request = await signForwardRequest(buyer, forwarder, exchange.target, data, deadline);

    // 6. Relayer (other) 调用 forwarder.execute 转发购买
    await expect(forwarder.connect(other).execute(request))
      .to.emit(forwarder, "ExecutedForwardRequest")
      .withArgs(buyer.address, 0n, true);

    // 7. 验证订单中记录 of buyerId 确实为 buyer 的 userId 
    expect(await exchange.buyerIdOf(0n)).to.equal(userId_buyer);
  });
});
