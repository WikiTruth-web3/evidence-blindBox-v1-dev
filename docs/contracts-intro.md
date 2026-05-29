# Evidence Market Sapphire 合约说明


**Evidence Market**项目中，有两个合约版本：

1. **contracts**：Oasis sapphire 加密版
   该合约是部署到 Sapphire Testnet 的公共测试版合约，包含完整的隐私保护和加密功能， 并且还增加了代理合约升级的功能，用于在公共测试过程中对合约进行完善。

2. **contracts-eth**：业务逻辑本地测试
   该合约目录是 **Evidence Market** 项目的 EVM 本地测试版本，用于在本地开发环境中测试 Evidence Market 核心功能。

## 🔄 与 contracts-eth 版本的区别

| 功能模块             | EVM 测试版本  | Sapphire 加密版本 |
| -------------------- | ------------- | ----------------- |
| **TEE 加密存储**     | ❌ 不支持     | ✅ 完整支持       |
| **SIWE 令牌验证**    | ❌ 不支持     | ✅ 完整集成       |
| **隐私代币**         | ❌ 标准 ERC20 | ✅ ERC20privacy   |
| **用户 ID 加密**     | ❌ 明文存储   | ✅ 加密存储       |
| **Sapphire 库**      | ❌ 移除       | ✅ 完整依赖       |
| **SiweAuth 合约**    | ❌ 不包含     | ✅ 独立合约       |
| **MultiDomain 支持** | ❌ 无         | ✅ 支持           |
| **隐私保护级别**     | 🔓 无保护     | 🔐 硬件级保护     |
| **生产环境**         | ❌ 仅供测试   | ✅ 可用于生产     |

## Sapphire 测试版本与 Sapphire 正式版的区别

| 功能模块     | 正式版本       | 测试版本       |
| ------------ | -------------- | -------------- |
| **时间期限** | 时间期限比较长 | 时间期限比较短 |

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

### 1. BlindBox（核心业务合约）🔐 支持加密存储

- **作用**：管理信息盒子的创建、交易等核心业务
- **功能**：
  - 信息盒子创建和管理
  - **关键信息加密存储**（利用 Sapphire 加密功能）
  - 保密费管理
  - 与 Exchange、FundManager 交互

### 2. Exchange（交易合约）

- **作用**：处理买卖交易
- **功能**：
  - 订单创建、匹配、完成
  - 支持多种隐私代币交易
  - 价格计算和验证
  - 与 FundManager 协同工作

### 3. FundManager（资金管理）

- **作用**：管理资金分配和提取
- **功能**：
  - 奖励分配（minter、seller、completer）
  - 资金提取（支持多代币）
  - 保密费结算

> 详细的业务流程见：[核心业务逻辑.md](./核心业务逻辑.md)。

## 🔑 非核心业务合约

### 1. AddressManager（地址管理合约）

- **作用**：统一管理所有项目合约地址和支持的代币
- **功能**：
  - 管理核心合约地址（Exchange、FundManager、BlindBox、SiweAuth 等）
  - 管理支持的隐私代币白名单
  - 管理项目合约授权（`_isProjectContract` mapping）
  - 管理保留地址列表

### 2. SiweAuth（SIWE 身份验证合约）⭐ Sapphire 特有

- **作用**：实现 Sign-In With Ethereum 身份验证
- **功能**：
  - 用户身份验证和会话管理
  - 支持多域名验证（MultiDomainSiweAuth）
  - 令牌生成和验证
  - 与 UserManager、BlindBox 等合约集成

### 3. UserManager（用户管理）🔐 支持加密

- **作用**：为用户地址分配唯一 ID，保护隐私
- **功能**：
  - 动态分配用户 ID
  - **加密存储用户 ID 映射**（利用 Sapphire TEE）
  - 黑名单管理
  - 通过 AddressManager 进行权限控制
  - 与 SiweAuth 集成 (sapphire 隐私合约独有)

### 4. Forwarder（元交易）

- **作用**：批量处理交易
- **功能**：
  - 实现 ERC2771 标准，支持元交易。
  - 批量提交多个交易请求，一次性支付 gas 费。
  - 代理支付 gas 费，并且实现链上隐身交易。
  - 搭配 UserManager 实现不可追踪的交易。

## 🔐 Sapphire 隐私功能特性

### 1. TEE 加密存储

```solidity
// 在 BlindBox 中加密存储敏感信息
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

// 加密存储关键数据
bytes memory encryptedKey = Sapphire.encrypt(...);
```

### 2. SIWE 身份验证

```solidity
// 使用 SIWE 令牌进行身份验证
bytes memory siweToken = ...;
address user = ISiweAuth(SIWE_AUTH).getMsgSender(siweToken);
```

### 3. 加密用户 ID

- 用户地址到 ID 的映射加密存储
- 保护用户隐私，防止链上追踪

### 4. ERC2771 元交易

- 支持代理支付 gas 费
- 实现链上隐身交易

### 5. PrivacyERC20

- 采用PrivacyERC20合约，实现链上资金不可追踪

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

---
