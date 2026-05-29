# Evidence Market Sapphire 合约说明

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

> 详细的业务流程见：[核心业务流程.md](./核心业务流程.md)。

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
