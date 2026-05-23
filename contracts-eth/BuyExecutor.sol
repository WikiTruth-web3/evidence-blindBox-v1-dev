// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IBuyExecutor} from "@interfaces/eth/IBuyExecutor.sol";
import {PaymentType} from "@interfaces/eth/IExchange.sol";
import {BuyExecutor01} from "./base/BuyExecutor01.sol";

/**
 * @title BuyExecutor
 * @notice Cross-chain execution entry contract (eth-test version).
 * Invoked only by the authorized backend executor.
 * Interacts with FundManagerCrossChain for payment verification and Exchange for status transitions.
 */
contract BuyExecutor is BuyExecutor01, IBuyExecutor {
    error EmptyTxHashes();
    error LengthMismatch();
    error BidPriceTooLow();

    // ===========================================================================

    constructor(address addrManager_, address executor_) BuyExecutor01(addrManager_, executor_) {
    }

    // ===========================================================================

    /**
     * @notice Performs a cross-chain purchase.
     */
    function buyWithExecutor(
        uint256 boxId_,
        bytes32 buyerUserId_,
        uint256 amount_,
        string calldata chain_,
        string calldata token_,
        string calldata txHash_
    ) external onlyExecutor {
        // 1. Record payment in FundManagerCrossChain (anti-replay checked inside)
        FUND_MANAGER_VIRTUAL.recordPayment(boxId_, buyerUserId_, amount_, chain, token_, txHash_);

        // 2. Call unified buy function in Exchange (handles status, timing, and ledger checks)
        EXCHANGE.buy(boxId_, buyerUserId_, PaymentType.CrossChain);

    }

    /**
     * @notice Performs a cross-chain bid with multiple transaction hashes merging.
     */
    function bidWithExecutor(
        uint256 boxId_,
        uint256 price_,
        bytes32 buyerUserId_,
        string calldata chain_,
        string calldata token_,
        uint256[] calldata amounts_,
        string[] calldata txHashes_
    ) external onlyExecutor {
        if (txHashes_.length == 0) revert EmptyTxHashes();
        if (txHashes_.length != amounts_.length) revert LengthMismatch();

        // 1. Record each individual payment and merge balances
        for (uint256 i = 0; i < txHashes_.length; i++) {
            FUND_MANAGER_VIRTUAL.recordPayment(boxId_, buyerUserId_, amounts_[i], chain, token_, txHashes_[i]);
        }

        // Retrieve current accumulated virtual balance
        uint256 balance = FUND_MANAGER_VIRTUAL.getVirtualAmount(boxId_, buyerUserId_);

        // 2. Call unified bid function in Exchange (handles status, timing, high bidder, and price checks)
        uint256 currentRequiredPrice = EXCHANGE.bid(boxId_, buyerUserId_, PaymentType.CrossChain);
        if (price_ < currentRequiredPrice) revert BidPriceTooLow();

    }

}
