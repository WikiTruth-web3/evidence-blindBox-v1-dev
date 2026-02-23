// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

interface ISiweAuth {
    function getMsgSender(bytes memory token_) external view returns (address);
}
