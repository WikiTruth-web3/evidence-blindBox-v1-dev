# 测试夹具模块化结构

本目录包含了重构后的测试夹具模块，将原本臃肿的 `Fixture.js` 文件拆分为多个功能模块。

## 模块结构

### 📁 contracts.js

**合约部署模块**

- 负责部署所有智能合约
- 包括：AddressManager、代币合约、交换合约等
- 返回签名者和合约实例

### 📁 connectors.js

**连接器模块**

- 为不同用户角色创建合约连接器实例
- 包括：TruthBox、Exchange、FundManager 等连接器
- 按功能分类组织连接器

### 📁 tokenConfig.js

**代币配置模块**

- 负责代币的铸造、授权和流动性配置
- 包括：测试代币铸造、授权设置、流动性添加
- 配置交换合约的代币对

### 📁 initialization.js

**初始化配置模块**

- 负责合约的初始参数设置和地址配置
- 包括：地址管理器配置、参数设置、测试数据生成
- 创建测试用的 TruthBox 项目

### 📁 index.js

**模块索引文件**

- 统一导出所有测试相关的模块
- 提供便捷的导入接口

## 使用方法

### 在测试文件中导入

```javascript
// 导入主夹具函数
const { deployTruthBoxFixture } = require("../Fixture");

// 或者导入特定模块
const { deployContracts, createConnectors } = require("./fixtures");
```

### 自定义测试配置

```javascript
const {
  deployContracts,
  configureTokens,
  initializeContracts,
} = require("./fixtures");

async function customFixture() {
  const { signers, contracts } = await deployContracts();
  // 自定义配置...
  return { signers, contracts };
}
```

## 优势

1. **模块化设计**：每个模块职责单一，便于维护
2. **代码复用**：各模块可独立使用，提高复用性
3. **易于测试**：可以单独测试每个模块的功能
4. **向后兼容**：保持原有 API 接口不变
5. **清晰结构**：代码组织更加清晰，便于理解

## 注意事项

- 保持向后兼容性，原有的测试文件无需修改
- 各模块之间有依赖关系，请按正确顺序调用
- 如需添加新的合约或配置，请在相应模块中添加
