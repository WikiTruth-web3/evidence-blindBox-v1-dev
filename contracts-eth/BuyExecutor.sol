// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {ModifierV2} from "./modifier/ModifierV2.sol";
import {IBuyExecutor} from "@interfaces/eth/IBuyExecutor.sol";
import {PaymentType} from "@interfaces/eth/IExchange.sol";
import {IFundManagerCrossChain} from "@interfaces/eth/IFundManagerCrossChain.sol";
import {CoreContracts} from "@interfaces/IContracts.sol";

/**
 * @title BuyExecutor
 * @notice Cross-chain execution entry contract (eth-test version).
 * Invoked only by the authorized backend executor.
 * Interacts with FundManagerCrossChain for payment verification and Exchange for status transitions.
 */
contract BuyExecutor is ModifierV2, IBuyExecutor {
    address public executor;
    IFundManagerCrossChain public fundManagerCrossChain;

    event ExecutorChanged(address indexed oldExecutor, address indexed newExecutor);
    event FundManagerCrossChainChanged(address indexed oldFmcc, address indexed newFmcc);
    event CrossChainPaymentRecorded(uint256 indexed boxId, bytes32 indexed buyerUserId, uint256 totalAmount);

    modifier onlyExecutor() {
        if (msg.sender != executor) revert InvalidCaller();
        _;
    }

    constructor(address addrManager_, address executor_) ModifierV2(addrManager_) {
        executor = executor_;
    }

    /**
     * @notice Set core contract addresses from AddressManager.
     */
    function setAddress() external onlyManager {
        _setAddress(CoreContracts.Exchange);
    }

    function setExecutor(address executor_) external onlyAdmin {
        emit ExecutorChanged(executor, executor_);
        executor = executor_;
    }

    function setFundManagerCrossChain(address fmcc_) external onlyAdmin {
        emit FundManagerCrossChainChanged(address(fundManagerCrossChain), fmcc_);
        fundManagerCrossChain = IFundManagerCrossChain(fmcc_);
    }

    /**
     * @notice Performs a cross-chain purchase.
     */
    function buyWithExecutor(
        uint256 boxId_,
        bytes32 buyerUserId_,
        uint256 amount_,
        string calldata chainToken_,
        string calldata txHash_
    ) external onlyExecutor {
        // 1. Record payment in FundManagerCrossChain (anti-replay checked inside)
        fundManagerCrossChain.recordPayment(boxId_, buyerUserId_, amount_, chainToken_, txHash_);

        // 2. Call unified buy function in Exchange (handles status, timing, and ledger checks)
        EXCHANGE.buy(boxId_, buyerUserId_, PaymentType.CrossChain);

        emit CrossChainPaymentRecorded(boxId_, buyerUserId_, amount_);
    }

    /**
     * @notice Performs a cross-chain bid with multiple transaction hashes merging.
     */
    function bidWithExecutor(
        uint256 boxId_,
        bytes32 buyerUserId_,
        string calldata chainToken_,
        uint256[] calldata amounts_,
        string[] calldata txHashes_
    ) external onlyExecutor {
        require(txHashes_.length > 0, "Empty tx hashes");
        require(txHashes_.length == amounts_.length, "Length mismatch");

        // 1. Record each individual payment and merge balances
        for (uint256 i = 0; i < txHashes_.length; i++) {
            fundManagerCrossChain.recordPayment(boxId_, buyerUserId_, amounts_[i], chainToken_, txHashes_[i]);
        }

        // Retrieve current accumulated virtual balance
        uint256 balance = fundManagerCrossChain.getVirtualAmount(boxId_, buyerUserId_);

        // 2. Call unified bid function in Exchange (handles status, timing, high bidder, and price checks)
        EXCHANGE.bid(boxId_, buyerUserId_, balance, PaymentType.CrossChain);

        emit CrossChainPaymentRecorded(boxId_, buyerUserId_, balance);
    }

    /**
     * @notice Clear virtual payments when buyer requests refund chain-off.
     */
    function clearVirtualBalance(
        uint256 boxId_,
        bytes32 buyerUserId_
    ) external onlyExecutor {
        fundManagerCrossChain.clearPayment(boxId_, buyerUserId_);
    }
}
