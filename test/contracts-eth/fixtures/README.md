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
