# WikiTruth Sapphire 正式版合约

## 📋 概述
**WikiTruth**项目中，有两个合约版本：

1. **Sapphire_test**：Oasis sapphire加密版
该合约是部署到 Sapphire Testnet 的公共测试版合约，包含完整的隐私保护和加密功能， 并且还增加了代理合约升级的功能，用于在公共测试过程中对合约进行完善。

2. **EVM**：逻辑测试
该合约目录是 **WikiTruth** 项目的 EVM 本地测试版本，用于在本地开发环境中测试 WikiTruth 核心功能。

## 🔄 与 EVM 测试版本的区别

| 功能模块 | EVM测试版本 | Sapphire测试版本 |
|---------|------------|----------------|
| **TEE加密存储** | ❌ 不支持 | ✅ 完整支持 |
| **SIWE令牌验证** | ⚠️ 部分注释 | ✅ 完整集成 |
| **隐私代币** | ❌ 标准ERC20 | ✅ ERC20Secret |
| **用户ID加密** | ❌ 明文存储 | ✅ 加密存储 |
| **Sapphire库** | ❌ 移除 | ✅ 完整依赖 |
| **SiweAuth合约** | ❌ 不包含 | ✅ 独立合约 |
| **MultiDomain支持** | ❌ 无 | ✅ 支持 |
| **隐私保护级别** | 🔓 无保护 | 🔐 硬件级保护 |
| **生产环境** | ❌ 仅供测试 | ✅ 可用于生产 |

## Sapphire 测试版本与正式版的区别

| 功能模块 | 正式版本 | 测试版本 |
|---------|------------|----------------|
| **Proxy** | ❌ 不支持 | ✅ 完整支持 |
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


## 📁 目录结构

```
contracts/
├── abstract/                      # 抽象合约（基础功能）
│   ├── ExchangeBase.sol          # 交易基础合约
│   ├── FeeRate.sol               # 费率管理
│   ├── FundManagerBase.sol       # 资金管理基础合约
│   ├── Modifier.sol              # 通用修饰符
│   ├── MultiDomainSiweAuth.sol   # 多域名SIWE认证（only Sapphire）
│   ├── ProxyUpgrade.sol          # 代理升级功能
│   └── TruthBoxBase.sol          # TruthBox基础合约
│
├── dex/                      # DEX相关合约 （only EVM）
│   ├── interfaceSwap.sol     # Swap接口定义
│   └── SwapContract.sol      # Swap实现合约
│
├── interfaceERC20/               # ERC20隐私代币接口（only Sapphire）
│   ├── ERC20SecretError.sol      # 隐私代币错误定义
│   ├── IERC20add.sol             # ERC20扩展接口
│   ├── IWROSE.sol                # Wrapped ROSE接口
│   └── draft-IERC6093.sol        # ERC6093草案
│
├── interfaces/                   # 接口定义
│   ├── IAddressManager.sol       # 地址管理接口
│   ├── IExchange.sol             # 交易接口
│   ├── IFundManager.sol          # 资金管理接口
│   ├── ISiweAuth.sol             # SIWE认证接口
│   ├── IQuoter.sol               # DEX价格查询接口
│   ├── ISwapRouter.sol           # DEX路由接口
│   ├── ITruthBox.sol             # TruthBox接口
│   ├── ITruthNFT.sol             # NFT接口
│   ├── IUserId.sol               # 用户ID接口
│   ├── interfaceError.sol        # 错误定义
│   └── siweAuthError.sol         # SIWE错误定义
│
├── library/                      # 工具库
│   └── StorageSlot.sol           # 存储槽工具
│
├── proxy/                        # 代理合约
│   └── Proxy_WikiTruth.sol       # WikiTruth代理合约
│
├── token/                        # 代币合约（Sapphire隐私代币）
│   ├── ERC20Secret.sol           # 隐私ERC20代币（核心）
│   ├── WROSEsecret.sol           # 隐私包装ROSE代币
│   └── MockERC20.sol             # 测试代币
│
├── test/                         # 测试相关文件
│
├── AddressManager.sol            # 地址管理合约（核心）
├── SiweAuth.sol                  # SIWE身份验证合约（Sapphire特有）
├── UserId.sol                    # 用户ID管理合约（支持加密）
├── TruthBox.sol                  # TruthBox核心合约（支持加密存储）
├── TruthNFT.sol                  # NFT合约
├── Exchange.sol                  # 交易合约
└── FundManager.sol               # 资金管理合约
```

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

### 3. UserId（用户ID管理）🔐 支持加密
- **作用**：为用户地址分配唯一ID，保护隐私
- **功能**：
  - 动态分配用户ID
  - **加密存储用户ID映射**（利用 Sapphire TEE）
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

### 7. TruthNFT（NFT合约）
- **作用**：管理项目相关的 NFT
- **功能**：铸造、转移、销毁等标准 NFT 功能

### 8. ERC20Secret（隐私代币）⭐ Sapphire 特有
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
- **ERC20Secret**：完全隐私保护的 ERC20 代币
- **WROSEsecret**：包装的隐私 ROSE 代币
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

1. **AddressManager**（最先部署）
   ```bash
   pnpm hardhat ignition deploy ignition/modules/AddressManager.ts --network sapphire-testnet
   ```

2. **SiweAuth**（身份验证合约）
   ```bash
   pnpm hardhat ignition deploy ignition/modules/SiweAuth.ts --network sapphire-testnet
   ```

3. **UserId**（用户ID管理）
   ```bash
   pnpm hardhat ignition deploy ignition/modules/UserId.ts --network sapphire-testnet
   ```

4. **TruthNFT**
   ```bash
   pnpm hardhat ignition deploy ignition/modules/TruthNFT.ts --network sapphire-testnet
   ```

5. **TruthBox**
   ```bash
   pnpm hardhat ignition deploy ignition/modules/TruthBox.ts --network sapphire-testnet
   ```

6. **Exchange**
   ```bash
   pnpm hardhat ignition deploy ignition/modules/Exchange.ts --network sapphire-testnet
   ```

7. **FundManager**
   ```bash
   pnpm hardhat ignition deploy ignition/modules/FundManager.ts --network sapphire-testnet
   ```

8. **隐私代币部署**（可选）
   ```bash
   pnpm hardhat ignition deploy ignition/modules/ERC20Secret.ts --network sapphire-testnet
   ```

9. **配置合约地址**
   ```bash
   # 调用 AddressManager.setAddressList() 设置所有地址
   # 调用 AddressManager.setAllAddress() 通知所有合约更新地址
   ```

### 网络配置

在 `hardhat.config.ts` 中已配置：

```typescript
networks: {
  'sapphire-testnet': {
    url: 'https://testnet.sapphire.oasis.io',
    chainId: 0x5aff,
    accounts: [PRIVATE_KEY]
  },
  'sapphire-mainnet': {
    url: 'https://sapphire.oasis.io',
    chainId: 0x5afe,
    accounts: [PRIVATE_KEY]
  }
}
```

## 🧪 测试说明

### Sapphire 网络测试

由于 Sapphire 的特殊性，**必须通过 OPL（Oasis Privacy Layer）进行跨链测试**：

```bash
# Sapphire 专用测试
pnpm hardhat test test/diagnostic/sapphire-test.ts --network sapphire-testnet
```

### 单元测试

```bash
# SIWE 认证测试
pnpm hardhat test test/single/SiweAuth.ts

# ERC20Secret 测试
pnpm hardhat test test/single/ERC20Secret.ts
```

### 本地快速测试

对于不涉及加密功能的核心业务逻辑，可以使用 EVM 版本测试：

```bash
# 使用 contracts/ 目录的 EVM 版本进行快速测试
pnpm hardhat test test/test-EVM/Exchange.js
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

### 4. 隐私代币集成

```solidity
import "./token/ERC20Secret.sol";

// 使用隐私代币
IERC20(secretToken).transfer(to, amount);
```

### 5. Gas 费用优化

Sapphire 的 gas 费用与以太坊类似，注意：
- 加密操作会增加 gas 消耗
- 批量操作时注意 gas limit
- 使用 `unchecked` 优化数学运算（已在代码中使用）

## 📚 相关资源

### 官方文档
- **Oasis Sapphire 文档**: https://docs.oasis.io/dapp/sapphire/
- **OPL 文档**: https://docs.oasis.io/dapp/opl/
- **Sapphire 合约库**: https://github.com/oasisprotocol/sapphire-paratime

### 项目相关
- **EVM 测试版本**: `contracts/` 目录
- **接口定义汇总**: `interfacesAll/` 目录
- **部署模块**: `ignition/modules/` 目录
- **测试脚本**: `test/` 目录

### 网络信息
- **Testnet Explorer**: https://testnet.explorer.sapphire.oasis.io/
- **Mainnet Explorer**: https://explorer.sapphire.oasis.io/
- **Testnet Faucet**: https://faucet.testnet.oasis.io/

## ⚠️ 重要安全提醒

### 1. 私钥安全
- ✅ 使用 `.env` 文件存储私钥（已添加到 `.gitignore`）
- ❌ 永远不要将私钥提交到代码库
- ✅ 生产环境使用硬件钱包或 KMS

### 2. 合约升级
- 使用 `ProxyUpgrade` 机制进行合约升级
- 升级前务必在 Testnet 充分测试
- 重要升级建议通过 DAO 治理

### 3. 加密数据
- Sapphire 的 TEE 加密是硬件级的，但仍需注意密钥管理
- 不要在前端明文传输敏感数据
- 使用 SIWE 令牌进行用户身份验证

### 4. Gas 费用
- Testnet 使用测试 ROSE，Mainnet 使用真实 ROSE
- 部署前估算好 gas 费用
- 建议保留充足的 ROSE 余额

### 5. 审计建议
- ✅ 合约已使用 OpenZeppelin 标准库
- ✅ 代码开源，遵循 GPL-2.0-or-later 协议
- ⚠️ 建议在 Mainnet 部署前进行专业安全审计

## 🔄 开发工作流

### 标准开发流程

1. **本地开发**
   - 在 `contracts/`（EVM版本）中开发核心逻辑
   - 使用 `test/test-EVM/` 快速测试

2. **Sapphire 集成**
   - 将测试通过的功能移植到 `contracts-truth/`
   - 添加 Sapphire 特有功能（加密、SIWE等）
   - 更新 SIWE 令牌验证逻辑

3. **Testnet 测试**
   - 部署到 Sapphire Testnet
   - 使用 OPL 进行跨链测试
   - 验证加密功能正常工作

4. **生产部署**
   - 完成安全审计
   - 部署到 Sapphire Mainnet
   - 监控合约运行状态

## 📝 版本信息

- **当前版本**: v1.7.7
- **网络环境**: Oasis Sapphire Testnet/Mainnet
- **Solidity 版本**: ^0.8.24
- **依赖库**:
  - `@oasisprotocol/sapphire-contracts`: ^0.2.14
  - `@oasisprotocol/sapphire-hardhat`: ^2.22.2
  - `@openzeppelin/contracts`: ^5.4.0
  - `siwe`: ^3.0.0
- **最后更新**: 2025-10

## 🎯 路线图

### 已完成 ✅
- [x] 核心合约开发（TruthBox、Exchange、FundManager）
- [x] 隐私代币集成（ERC20Secret）
- [x] SIWE 身份验证
- [x] DEX 集成（Swap 功能）
- [x] 代理升级机制
- [x] 多代币支持
- [x] 动态授权机制

### 进行中 🚧
- [ ] 完善跨链功能（OPL 集成）
- [ ] Gas 优化
- [ ] 安全审计准备

### 规划中 📅
- [ ] DAO 治理模块
- [ ] 更多 DEX 协议集成
- [ ] Layer2 扩展方案
- [ ] 移动端 SDK

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

*保护隐私，传播真相 - WikiTruth*
