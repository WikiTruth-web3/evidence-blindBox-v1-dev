  Exchange 交易流程事件测试
    ✔ 00-mint: minter 铸造 BlindBox 事件 (249ms)
    ✔ 01-sell+auction: minter 上架触发 Exchange + BlindBox 事件
    ✔ 02-sell+auction: seller 上架触发 Exchange + BlindBox 事件
    ✔ 02-buy: 购买触发状态变化 + 购买 + 退款截止时间事件
    ✔ 03- bid: 竞拍触发出价、价格、截止时间事件、支付资金， 竞拍失败后，提取order资金
    ✔ 04-refund 流程: requestRefund + agreeRefund 触发对应事件
    ✔ 05-completeOrder: 非买家完成订单触发 CompleterAssigned + 状态变更 (43ms)
    1) 06-completeOrder: 非买家完成订单, 非settlementToken支付, 


  7 passing (456ms)
  1 failing

  1) Exchange 交易流程事件测试
       06-completeOrder: 非买家完成订单, 非settlementToken支付, :
     AssertionError: The specified arguments ([ 1, '0x5FbDB2315678afecb367f032d93F642f64180aa3', 40, 2 ]) were not included in any of the 2 emitted "RewardAdded" events
      at async Context.<anonymous> (test\contracts-eth\EmitTest.js:274:5)