# WikiTruth Sapphire 正式版合约

## 📋 概述

**WikiTruth**项目中，有两个合约版本：

1. **Sapphire_test**：Oasis sapphire 加密版
   该合约是部署到 Sapphire Testnet 的公共测试版合约，包含完整的隐私保护和加密功能， 并且还增加了代理合约升级的功能，用于在公共测试过程中对合约进行完善。

2. **EVM**：逻辑测试
   该合约目录是 **WikiTruth** 项目的 EVM 本地测试版本，用于在本地开发环境中测试 WikiTruth 核心功能。

## 🔄 与 EVM 测试版本的区别

| 功能模块             | EVM 测试版本  | Sapphire 测试版本 |
| -------------------- | ------------- | ----------------- |
| **TEE 加密存储**     | ❌ 不支持     | ✅ 完整支持       |
| **SIWE 令牌验证**    | ⚠️ 部分注释   | ✅ 完整集成       |
| **隐私代币**         | ❌ 标准 ERC20 | ✅ PrivacyERC20   |
| **用户 ID 加密**     | ❌ 明文存储   | ✅ 加密存储       |
| **Sapphire 库**      | ❌ 移除       | ✅ 完整依赖       |
| **SiweAuth 合约**    | ❌ 不包含     | ✅ 独立合约       |
| **MultiDomain 支持** | ❌ 无         | ✅ 支持           |
| **隐私保护级别**     | 🔓 无保护     | 🔐 硬件级保护     |
| **生产环境**         | ❌ 仅供测试   | ✅ 可用于生产     |

## Sapphire 测试版本与正式版的区别

| 功能模块     | 正式版本       | 测试版本       |
| ------------ | -------------- | -------------- |
| **Proxy**    | ❌ 不支持      | ✅ 完整支持    |
| **时间期限** | 时间期限比较长 | 时间期限比较段 |

### 为什么选择 Oasis Sapphire？

1. **TEE 可信执行环境**：提供硬件级别的数据加密和隐私保护
2. **链上隐私计算**：支持加密状态存储和私密交易
3. **EVM 兼容**：完全兼容以太坊生态，开发体验友好
4. **真正的隐私保护**：用户地址、交易详情等敏感信息均可加密存储
5. **SIWE 身份验证**：Sign-In With Ethereum，提供安全的用户身份验证

### 为什么需要 EVM 测试版本？

1. **Sapphire 本地网络不稳定**：在本地运行 Oasis Sapphire 网络存在稳定性问题
2. **无法真实模拟 TEE 加密**：本地环境无法完整模拟 Sapphire 的 TEE（可信执行环境）加密功能
3. **测试效率优化**：移除 Sapphire 相关依赖后，测试流程更简单高效
4. **快速迭代开发**：便于快速验证核心业务逻辑

## 🔑 核心合约说明

### 1. AddressManager（地址管理合约）

- **作用**：统一管理所有项目合约地址和支持的代币
- **功能**：
  - 管理核心合约地址（Exchange、FundManager、TruthBox、SiweAuth 等）
  - 管理支持的隐私代币白名单
  - 管理项目合约授权（`_isProjectContract` mapping）
  - 管理 DEX 相关地址（SwapRouter、Quoter）
  - 管理保留地址列表

### 2. SiweAuth（SIWE 身份验证合约）⭐ Sapphire 特有

- **作用**：实现 Sign-In With Ethereum 身份验证
- **功能**：
  - 用户身份验证和会话管理
  - 支持多域名验证（MultiDomainSiweAuth）
  - 令牌生成和验证
  - 与 UserId、TruthBox 等合约集成

### 3. UserId（用户 ID 管理）🔐 支持加密

- **作用**：为用户地址分配唯一 ID，保护隐私
- **功能**：
  - 动态分配用户 ID
  - **加密存储用户 ID 映射**（利用 Sapphire TEE）
  - 黑名单管理
  - 通过 AddressManager 进行权限控制
  - 与 SiweAuth 集成

### 4. TruthBox（核心业务合约）🔐 支持加密存储

- **作用**：管理信息盒子的创建、交易等核心业务
- **功能**：
  - 信息盒子创建和管理
  - **关键信息加密存储**（利用 Sapphire 加密功能）
  - 保密费管理
  - NFT 铸造集成
  - 与 Exchange、FundManager 交互

### 5. Exchange（交易合约）

- **作用**：处理买卖交易
- **功能**：
  - 订单创建、匹配、完成
  - 支持多种隐私代币交易
  - 价格计算和验证
  - 与 FundManager 协同工作

### 6. FundManager（资金管理）

- **作用**：管理资金分配和提取
- **功能**：
  - 奖励分配（minter、helper）
  - 资金提取（支持多代币）
  - DEX 集成（通过 SwapRouter 兑换代币）
  - 滑点保护
  - 保密费结算

### 6. ERC20Secret（隐私代币）⭐ Sapphire 特有

- **作用**：实现隐私保护的 ERC20 代币
- **功能**：
  - 标准 ERC20 功能
  - **余额加密存储**（利用 Sapphire TEE）
  - 隐私转账
  - 与 WikiTruth 生态集成

## 🔐 Sapphire 隐私功能特性

### 1. TEE 加密存储

```solidity
// 在 TruthBox 中加密存储敏感信息
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

// 加密存储关键数据
bytes memory encryptedKey = Sapphire.encrypt(...);
```

### 2. 隐私代币系统

- **PrivacyERC20**：完全隐私保护的 ERC20 代币
- **PrivacyWROSE**：包装的隐私 ROSE 代币
- 余额和转账记录加密存储

### 3. SIWE 身份验证

```solidity
// 使用 SIWE 令牌进行身份验证
bytes memory siweToken = ...;
address user = ISiweAuth(SIWE_AUTH).getMsgSender(siweToken);
```

### 4. 加密用户 ID

- 用户地址到 ID 的映射加密存储
- 保护用户隐私，防止链上追踪

## 🚀 部署指南

### 前置准备

1. **获取 ROSE 测试代币**

   - Testnet Faucet: https://faucet.testnet.oasis.io/
   - 需要 ROSE 用于支付 gas 费用

2. **配置私钥**

   ```bash
   export PRIVATE_KEY=0x...
   ```

3. **安装依赖**
   ```bash
   pnpm install
   ```

### 编译合约

```bash
pnpm hardhat compile
```

### 部署顺序

**推荐使用 Ignition 部署方式**（保证编译文件持久化）：

1. **AddressManager**（最先部署）,其它合约依赖 AddressManager

2. **配置合约地址**
   ```bash
   # 调用 AddressManager.setAddressList() 设置所有地址
   # 调用 AddressManager.setAllAddress() 通知所有合约更新地址
   ```

## 🧪 测试说明

### Sapphire 网络测试

由于 Sapphire 版本集成了 uniswap-v3，所以测试时无法在本地进行测试，我们直接使用 Sapphire 测试网络进行测试：

```bash
# Sapphire 专用测试
pnpm hardhat test test/diagnostic/sapphire-test.ts --network sapphire-testnet
```

### 本地快速测试

加密业务逻辑无法在本地进行测试，我们直接使用 EVM 版本进行测试：

```bash
# 使用 contracts/ 目录的 eth 版本进行快速测试
pnpm hardhat test test/test-eth/Exchange.js
```

## 🔧 开发注意事项

### 1. 使用 Sapphire 加密功能

```solidity
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

// 加密数据
bytes memory encrypted = Sapphire.encrypt(
    key,
    nonce,
    plaintext,
    additionalData
);

// 解密数据
bytes memory decrypted = Sapphire.decrypt(
    key,
    nonce,
    ciphertext,
    additionalData
);

// 生成随机数（使用 TEE 的真随机数）
bytes32 randomValue = bytes32(Sapphire.randomBytes(32, ""));
```

### 2. SIWE 令牌验证

```solidity
// 在需要用户身份验证的函数中
function sensitiveOperation(bytes memory siweToken_) external {
    address user = ISiweAuth(SIWE_AUTH).getMsgSender(siweToken_);
    // 使用验证后的用户地址进行操作
}
```

### 3. 权限控制优化

使用动态授权机制，避免硬编码：

```solidity
// ✅ 推荐方式：动态检查
if (!ADDR_MANAGER.isProjectContract(msg.sender)) {
    revert InvalidCaller();
}
```

### 4. DEX（uniswa-v3）集成

只需要使用 uniswap-v3 和 quoter 即可

## 📚 相关资源

### 官方文档

- **Oasis Sapphire 文档**: https://docs.oasis.io/dapp/sapphire/
- **OPL 文档**: https://docs.oasis.io/dapp/opl/
- **Sapphire 合约库**: https://github.com/oasisprotocol/sapphire-paratime

### 项目相关

- **合约**: `contracts/` 目录
- **核心合约接口定义**: `marketplace-v1/` 目录
- **uniswap-v3 接口**: `uniswap-v3/` 目录
- **隐私代币合约**: `privacy-erc20/` 目录
- **部署模块**: `ignition/modules/` 目录
- **测试脚本**: `test/` 目录

### 网络信息

- **Testnet Explorer**: https://testnet.explorer.sapphire.oasis.io/
- **Mainnet Explorer**: https://explorer.sapphire.oasis.io/
- **Testnet Faucet**: https://faucet.testnet.oasis.io/

## 🤝 贡献指南

欢迎社区贡献！开发新功能时：

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 先在 EVM 版本测试核心逻辑
4. 移植到 Sapphire 版本并添加隐私功能
5. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
6. 推送分支 (`git push origin feature/AmazingFeature`)
7. 提交 Pull Request

### 代码规范

- ✅ 使用中文注释
- ✅ 遵循 Solidity 风格指南
- ✅ 添加完整的 NatSpec 注释
- ✅ 确保所有测试通过
- ✅ Gas 优化（使用 `unchecked` 等）

---

## 📞 联系方式

- **Website**: [https://wikitruth.eth.limo/](https://wikitruth.eth.limo/)
- **License**: GPL-2.0-or-later

---

**Built with ❤️ on Oasis Sapphire**

_保护隐私，传播真相 - WikiTruth_
