/**
 * 交互脚本所需要的公共枚举与非合约数据结构
 */

export enum Main {
    BlindBox= 0,
    Exchange= 1,
    FundManager= 2,
    UserManager= 3,
    // ---------------
    SiweAuth= 4, // 4
    Forwarder= 5,
    // -----
    Dao= 6, // 6
    DaoTreasury= 7,
    Governance=8
}


export enum BoxStatus {
    Storing = 0,
    Selling = 1,
    Auctioning = 2,
    Paid = 3,
    Delaying = 4,
    Refunding = 5,
    Published = 6,
    Blacklisted = 7
}

export enum RewardType {
    Minter = 0,
    Seller = 1,
    Completer = 2
}

export enum FundType {
    Order = 0,
    Refund = 1
}
