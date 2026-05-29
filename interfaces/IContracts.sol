// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

enum Main {
    BlindBox, // 0
    Exchange,  // 1
    FundManager, // 2
    UserManager,
    // ---------------
    SiweAuth, // 4
    Forwarder,
    // -----
    Staking, // 6
    Dao,
    DaoTreasury,
    Governance
}