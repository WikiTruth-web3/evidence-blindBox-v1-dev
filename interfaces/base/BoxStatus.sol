// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

enum BoxStatus {
    Storing,
    Selling,
    Auctioning,
    Paid,
    Delaying,
    Refunding, // NOTE 
    Published,
    Blacklisted
}

