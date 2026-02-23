# ERC-2771 Meta-Transaction 代理交互说明

1. 项目合约的交互有两类，一类是管理员权限交互，这类函数不需要实现代理交互（write）功能，另一类才是普通用户调用的函数，这类才需要使用代理交互（write）。
2. 关于合约，只有 TruthBox、Exchange、FundManager 合约才有普通用户的 write 操作，所有也只有这几个合约需要增加 ERC-2771 代理交互功能。

## TruthBox

以下是 TruthBox 需要实现代理交互的函数：
create、createAndPublish、publishByMinter、publishByBuyer、extendDeadline、delay

## Exchange

以下是 Exchange 需要实现代理交互的函数：
sell、auction、buy、bid、requestRefund、cancelRefund、agreeRefund、completeOrder

## FundManager

withdrawOrderAmounts、withdrawRefundAmounts、withdrawHelperRewards、withdrawMinterRewards
