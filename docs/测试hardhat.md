# Hardhat 本地合约业务逻辑测试说明文档

本文件旨在对 `contracts-eth` 目录下的以太坊测试版合约（主要包含 `BlindBox`、`Exchange`、`FundManager`、`UserManager` 等核心逻辑）在 Hardhat 本地测试环境中的自动化测试场景进行全面说明。

---

## 🧪 一、 核心基础流程测试 (Happy Path)

主要测试一口价（Fixed Price）盲盒从铸造、上架、购买到结算与延期的标准流转。

### 1. 盲盒创建
- **测试场景**：Minter 铸造盲盒。
- **验证点**：
  - 调用 `BlindBox.create()`。
  - 验证生成唯一的 `boxId`。
  - 验证初始状态为 `Storing`。
  - 验证盲盒保护期 `deadline` 被自动设为 `当前区块时间 + 365 天`。
  - 验证机密敏感数据 `_secretData` 正确保存。

### 2. Minter 一口价上架
- **测试场景**：Minter 将盲盒上架销售。
- **验证点**：
  - 调用 `Exchange.sell()`，设定支持的 ERC20 交易代币（`acceptedToken`）与价格。
  - 验证盲盒状态变更为 `Selling`。

### 3. 买家正常购买
- **测试场景**：买家购买处于 `Selling` 状态下的盲盒。
- **验证点**：
  - 买家调用 `Exchange.buy()`。
  - 验证 `acceptedToken` 成功通过 `transferFrom` 扣款并划入 `FundManager` 合约。
  - 验证盲盒状态变更为 `Paid`，`buyerId` 记账为买家的 `userId`。
  - 验证买家退款截止时间 `refundRequestDeadline` 设为 `当前区块时间 + 7 天`。

### 4. 订单结算与收益分配
- **测试场景**：买家确认没有问题，完成订单。
- **验证点**：
  - 买家（或 Minter 超过 7 天）调用 `Exchange.completeOrder()`。
  - 验证盲盒状态变更为 `Delaying`。
  - 验证 `FundManager` 内收益分配：
    - DAO 资金池（`DAO_TREASURY`）直接收到 `serviceFeeRate` 的服务费代币。
    - Minter 在 `FundManager` 的奖励余额增加（大头）。
    - 相应 Helper（如 Seller, Completer）在 `FundManager` 的奖励余额增加。
    - 原交易锁定额度 `_orderAmounts[boxId][buyer]` 归零。

### 5. 延期披露
- **测试场景**：买家希望延长敏感数据的保密时间，支付延期披露费。
- **验证点**：
  - 盲盒处于 `Delaying` 状态，且在到期前 30 天的窗口期内。
  - 任何人（通常为买家）调用 `BlindBox.delay()`。
  - 扣除原交易价格等额的 `settlementToken` 作为延期披露费。
  - 验证盲盒的 `deadline` 顺延 `365 天`，下次延期价格按 `_incrementRate` (200%) 翻倍。

---

## ⚖️ 二、 退款与安全博弈机制测试

测试买家退款、数据被自动公开的特殊惩罚机制，以及超期仲裁。

### 6. 申请退款触发数据公开
- **测试场景**：买家申请退款以测试防白嫖博弈威慑。
- **验证点**：
  - 买家在 `Paid` 状态下且 7 天内调用 `Exchange.requestRefund()`。
  - 验证状态变更为 `Refunding`。
  - **博弈公开性验证**：在此状态下，非 Minter、非 Buyer 成员（如第三方地址）调用 `BlindBox.getSecretData()`，验证能够直接成功读取并解密机密敏感数据（数据强制公开）。

### 7. 仲裁期内同意退款
- **测试场景**：卖家（Minter）或 DAO 在 15 天仲裁期内同意退款。
- **验证点**：
  - 卖家调用 `Exchange.agreeRefund()`。
  - 验证状态变更为 `Published`，`refundPermit` 设为 `true`。
  - 买家调用 `FundManager.withdrawRefundAmounts()`。
  - 验证买家成功全额取回质押代币。

### 8. 仲裁期内 DAO 拒绝退款
- **测试场景**：DAO 认为买家恶意退款，裁定拒绝。
- **验证点**：
  - DAO 调用 `Exchange.refuseRefund()`。
  - 验证状态恢复为 `Delaying`。
  - 验证资金按结算规则分配给 Minter，并向 DAO 划转服务费。

### 9. 仲裁超期自动放行
- **测试场景**：申请退款后，卖家与 DAO 在 15 天内未做任何处理。
- **验证点**：
  - 区块时间增加 15 天以上。
  - 任何人调用 `Exchange.agreeRefund()`。
  - 验证调用成功，状态变更为 `Published`，`refundPermit` 自动设为 `true`。买家可成功取出退款。

---

## 🔨 三、 拍卖（Auction）竞价与退款限制测试

测试竞拍模式中的价格递增、资金追加、超期退款惩罚。

### 10. 拍卖初始化与首次出价
- **测试场景**：Minter 挂单拍卖，买家 A 首次出价。
- **验证点**：
  - 调用 `Exchange.auction()`，状态变为 `Auctioning`，截止时间设为 30 天后。
  - 买家 A 调用 `Exchange.bid()`。
  - 验证 A 扣除首次竞拍款，状态仍为 `Auctioning`，当前 `buyer` 为 A。
  - 验证截止时间 `deadline` 顺延 365 天（或测试网 15 天），且退款期限 `refundRequestDeadline` 随之增加（+30 天）。

### 11. 竞价被超出与旧资金提取
- **测试场景**：买家 B 以 1.1 倍的更高价格参与竞买。
- **验证点**：
  - 买家 B 调用 `Exchange.bid()`，扣除更高额代币，B 成为当前 `buyer`。
  - **资金退回**：被超出的出价者 A 调用 `FundManager.withdrawOrderAmounts()`。
  - 验证 A 成功取回原本质押的首次出价代币，且 A 不能在 B 成为 buyer 时调用 `requestRefund`。

### 12. 余额保留追加出价
- **测试场景**：买家 A 不提取旧竞拍款，直接进行二次加价竞拍。
- **验证点**：
  - 当前价格已涨为 110，A 之前投入了 100（尚未取回）。
  - A 再次调用 `Exchange.bid()`。
  - **差额扣款验证**：验证 A 的钱包只被扣除了差额的 `10` 单位代币（110 - 100）。
  - 验证 A 重新成为当前 `buyer`，余额累计为 110。

### 13. 拍卖结束与退款限制
- **测试场景**：拍卖过期未有人出价，最终获胜买家测试退款。
- **验证点**：
  - 区块时间走过 30 天，无新竞价。
  - 盲盒状态动态流转为 `Paid`。
  - **超期惩罚**：买家在过期（例如出价 30 天后）调用 `requestRefund()`。
  - 验证：由于买家最终出价已经过了退款期限（补充了 `+30天` 但在此之后），调用 `requestRefund()` 无法申请退款，直接自动走入 `else` 分支并强行完成结算，资金分给 Minter，无法退款。

---

## 🔮 四、 预言机价格折算与资金配平测试 (Oracle Integration)

测试使用非结算代币交易时，Helper 奖励通过 Oracle 自动折算为项目结算代币并划转代币至 DAO。

### 14. 部署与注册模拟预言机
- **测试场景**：测试网模拟喂价注册。
- **验证点**：
  - 部署 `MockPriceOracle`。
  - 用 Admin 账号在 `AddressManager` 注册 `mockOracle` 地址为 `"PriceOracle"` 扩展合约。
  - 调用 `mockOracle.setPrice(TokenA, TokenS, 2 * 1e18)`（设定 1 TokenA = 2 TokenS）。

### 15. Helper 奖励结算折算
- **测试场景**：使用 `TokenA` 购买盲盒，结算时 Helper 获得 `TokenS`，DAO 得到 `TokenA`。
- **验证点**：
  - 创建盲盒并上架以 `TokenA` 交易，价格为 1000 TokenA，Helper 费率为 1%（10 TokenA）。
  - 买家支付 1000 TokenA 完成购买。
  - 调用 `Exchange.completeOrder()`。
  - **折算配平验证**：
    - 验证 Helper（例如 Seller）账面增加的结算代币奖励为 `20 TokenS`（10 TokenA * 2 汇率）。
    - 验证 `DAO_TREASURY` 地址收到的 `TokenA` 总额为 `serviceFee + Helper代币`（例如 30 + 10 = 40 TokenA）。
    - 验证 Minter 获得的 `TokenA` 依旧为扣除 Helper 原数额及服务费后的 `960 TokenA`。
    - 验证 `FundManager` 合约内部不存在资金盈余，`TokenA` 的转移完美闭环。

---

## 🛡️ 五、 异常与权限边界测试 (Edge Cases)

### 16. 保护期内防黄牛与代挂单限制
- **测试场景**：非 Minter 用户尝试强行代上架未过保护期的盲盒。
- **验证点**：
  - 盲盒在 `Storing` 状态，保护期 `deadline` 尚未到期。
  - 非 Minter 调用 `Exchange.sell()` 或 `Exchange.auction()`。
  - 验证交易被 revert，错误为 `DeadlineNotOver()`。

### 17. 保护期过后代挂单抽成
- **测试场景**：盲盒保护期已过，非 Minter 强制代上架。
- **验证点**：
  - 盲盒保护期已过。
  - 非 Minter 成功调用 `Exchange.sell()`。
  - 验证盲盒价格没有被改变（传入价格 0 触发保留原价）。
  - 验证 `_boxExchengData` 中的 `_sellerId` 设为此非 Minter 用户的 `userId`。
  - 订单结算时，验证该非 Minter 用户成功分得 1% 的 `helperRewards` 作为挂单抽成。

### 18. 黑名单封禁限制
- **测试场景**：违规盲盒或用户被列入黑名单。
- **验证点**：
  - DAO 调用 `BlindBox.addToBlacklist()`，验证状态变为 `Blacklisted`，如果是已支付，验证 `refundPermit` 设为 `true`。
  - 验证已被黑名单的盲盒无法再执行 `sell`、`auction` 或 `buy`。
  - 验证被 `UserManager` 列入黑名单的用户，在调用 `myUserId` 等方法时直接被拒。

### 19. 跨合约权限校验限制
- **测试场景**：恶意用户直接调用 `BlindBox` 中受 `onlyProjectContract` 保护的敏感状态设置函数。
- **验证点**：
  - 外部钱包地址直接调用 `BlindBox.setStatus()`。
  - 验证交易直接被 revert，错误为 `NotProjectCaller()`。

### 20. 元交易 ERC-2771 签名转发执行
- **测试场景**：Relayer 代用户执行业务，验证真实调用者身份。
- **验证点**：
  - 构造 `ForwardRequestData` 并在前端签名。
  - Relayer 调用 `Forwarder.execute()` 转发请求。
  - 验证 `_msgSender()` 成功返回签名用户的 `userId` 并完成数据创建或购买，同时 `msg.sender` 依旧为 `Forwarder` 合约地址。
