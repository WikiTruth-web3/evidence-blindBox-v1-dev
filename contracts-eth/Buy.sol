// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IBuy} from "@interfaces/eth/IBuy.sol";
import {PaymentType} from "@interfaces/eth/IExchange.sol";
import {ModifierV2} from "./modifier/ModifierV2.sol";
import {CoreContracts} from "@interfaces/IContracts.sol";

/**
 * @title Buy
 * @notice Native chain entry contract for buying and bidding BlindBoxes using ERC20 tokens (eth-test version).
 */
contract Buy is ModifierV2, IBuy {
    constructor(address addrManager_) ModifierV2(addrManager_) {}

    /**
     * @notice Set core contract addresses from AddressManager.
     */
    function setAddress() external onlyManager {
        _setAddress(CoreContracts.Exchange);
    }

    /**
     * @notice Buy a box on the native chain.
     * @param boxId_ The ID of the BlindBox to purchase.
     */
    function buy(uint256 boxId_) external {
        address sender = msg.sender;
        bytes32 userId = USER_MANAGER.getUserId(sender);
        uint256 payAmount = BLIND_BOX.getPrice(boxId_);

        // 1. Charge ERC20 from buyer via FundManager
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount, userId);

        // 2. Transition state in Exchange
        EXCHANGE.buy(boxId_, userId, PaymentType.Native);
    }

    /**
     * @notice Place a bid on an auction box on the native chain.
     * @param boxId_ The ID of the BlindBox in auction.
     */
    function bid(uint256 boxId_) external {
        address sender = msg.sender;
        bytes32 userId = USER_MANAGER.getUserId(sender);
        uint256 price = BLIND_BOX.getPrice(boxId_);

        // Calculate pay money (price - accumulated balance)
        uint256 balance = FUND_MANAGER.restrictedGetOrderAmounts(boxId_, userId);
        require(price > balance, "Bid price must be greater than current balance");
        uint256 payAmount = price - balance;

        // 1. Pay incremental bid money
        FUND_MANAGER.payOrderAmount(boxId_, sender, payAmount, userId);

        // 2. Set new bid status in Exchange
        EXCHANGE.bid(boxId_, userId, price, PaymentType.Native);
    }
}
