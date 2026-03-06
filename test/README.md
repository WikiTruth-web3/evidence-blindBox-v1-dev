# WikiTruth 测试套件

WikiTruth 项目包含两个版本的合约和对应的测试套件:

## 📁 项目结构

```
test/
├── contracts-eth/                   # eth 版本测试 (JavaScript)
│   ├── *.js                   # 测试文件
│   └── fixtures/              # 测试固件
│
├── utils/                     # 工具函数 (TypeScript)
│   ├── common.ts             # 通用工具
│   ├── getAccount.ts         # 账户管理
│   ├── getSiweAuth.ts        # SIWE 认证
│   ├── connectContracts.ts  # 合约连接
│   └── index.ts             # 导出索引
│
├── single/                    # 单独测试
│   ├── SiweAuth.ts           # SiweAuth 合约测试
│   └── ERC20Secret.ts        # ERC20Secret 测试
│
└── README.md                  # 本文档
```

## 🔑 两个版本的差异

### eth 版本 (contracts-eth/)

- **语言**: JavaScript
- **网络**: 以太坊 eth 兼容网络
- **认证**: msg.sender
- **加密**: 无加密功能
- **状态**: ✅ 已完成并通过所有测试

### Sapphire 版本 (test/sapphire/)

- **语言**: TypeScript
- **网络**: Oasis Sapphire 隐私网络
- **认证**: ✅ 使用 SiweAuth 令牌认证
- **加密**: ✅ 使用 Sapphire 加密库 (隐式)
- **状态**: ✅ 新创建,专业化设计

## 🚀 快速开始

### 运行 eth 版本测试

```bash
# 运行所有 eth 测试
npx hardhat test test/contracts-eth/*.js

# 运行特定测试
npx hardhat test test/contracts-eth/TruthBox.js
npx hardhat test test/contracts-eth/Exchange.js
```

## 📊 测试覆盖对比

| 功能模块             | eth 版本 | Sapphire 版本 |
| -------------------- | -------- | ------------- |
| TruthBox 基本功能    | ✅       | ✅            |
| Exchange 交易功能    | ✅       | ✅            |
| FundManager 资金管理 | ✅       | ✅            |
| TruthNFT NFT 功能    | ✅       | ✅            |
| UserManager 用户管理 | ✅       | ✅            |
| SiweAuth 认证        | ❌       | ✅            |
| Sapphire 加密        | ❌       | ✅ (隐式)     |
| 集成测试             | ✅       | ✅            |

## 🔧 Sapphire 版本的关键特性

### 1. SiweAuth 集成

Sapphire 版本的核心差异是使用了 SiweAuth 进行令牌认证:

```typescript
// 在 fixture 初始化时生成 tokens
const { siweTokens } = await generateSiweAuthTokens(
  accounts,
  contracts,
  connectors,
  chainId,
);
```

### 3. TypeScript 类型安全

所有接口和类型都有明确定义:

```typescript
export interface TestAccounts {
  admin: Wallet;
  minter: Wallet;
  buyer: Wallet;
  buyer2: Wallet;
  seller: Wallet;
  completer: Wallet;
}

export interface DeployedContracts {
  addressManager: Contract;
  settlementToken: Contract;
  wBTC: Contract;
  otherToken: Contract;
  otherToken2: Contract;
  truthBox: Contract;
  swapContract: Contract;
  fundManager: Contract;
  exchange: Contract;
  userManager: Contract;
}
```

## 📝 编写新测试

### eth 版本

```javascript
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { deployTruthBoxFixture } = require("./Fixture.js");

describe("我的测试", function () {
  it("应该...", async function () {
    const { admin, truthBox, exchange } = await loadFixture(
      deployTruthBoxFixture,
    );
    // 测试逻辑
  });
});
```

## 🌐 支持的网络

### eth 版本

- Hardhat 本地网络 (默认)
- 任何 eth 兼容网络

### Sapphire 版本

- `sapphire_localnet` (chainId: 23293) - 本地测试网
- `sapphire_testnet` (chainId: 23294) - Sapphire 测试网
- `sapphire_mainnet` (chainId: 23295) - Sapphire 主网

## 🛠️ 工具函数

项目提供了丰富的工具函数 (位于 `test/utils/`):

### 账户管理

```typescript
import { getAccount } from "./utils/getAccount";

const accounts = await getAccount(chainId);
// { admin, minter, buyer, buyer2, seller, completer }
```

### SIWE 认证

```typescript
import { siweMsg, erc191sign } from "./utils/getSiweAuth";

const message = await siweMsg({ domain, signer, chainId });
const signature = await erc191sign(message, signer);
```

### 合约连接

```typescript
import { connectContract } from "./utils/connectContracts";

const connectedContract = await connectContract(contract, signer);
```

### 通用工具

```typescript
import { sleep, waitForBlocks, getBalance } from "./utils/common";

await sleep(1000); // 等待 1 秒
await waitForBlocks(10); // 等待 10 个区块
const balance = await getBalance(address); // 获取余额
```

## 🐛 故障排除

### 问题: 测试超时

**解决方案**:

```typescript
describe("我的测试", function () {
  this.timeout(60000); // 增加超时到 60 秒

  it("应该...", async function () {
    // 测试代码
  });
});
```

### 问题: SiweAuth token 过期

**解决方案**: Token 默认有效期为 24 小时,如果测试运行时间很长,可能需要重新生成 token。

## 📚 参考资料

- [Hardhat 文档](https://hardhat.org/docs)
- [Oasis Sapphire 文档](https://docs.oasis.io/dapp/sapphire/)
- [SIWE 规范](https://eips.ethereum.org/EIPS/eip-4361)
- [Chai 断言库](https://www.chaijs.com/)
- [Mocha 测试框架](https://mochajs.org/)

## 🤝 贡献指南

1. 遵循现有的代码风格
2. 为新功能添加测试
3. 确保所有测试通过
4. 更新相关文档

## 📄 许可证

Apache-2.0
