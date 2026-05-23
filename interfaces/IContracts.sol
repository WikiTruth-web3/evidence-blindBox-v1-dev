// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

enum CoreContracts {
    BlindBox,
    Exchange,
    FundManager,
    UserManager
}

enum PeripheralContracts {
    Buy,
    // Corss Chain Contracts
    BuyExecutor, 
    FundManagerVirtual,
    Forwarder,
    SwapContract,
    Quoter

}
