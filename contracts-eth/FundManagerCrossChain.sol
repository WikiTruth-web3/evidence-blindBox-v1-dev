// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {ModifierV2} from "./modifier/ModifierV2.sol";
import {IFundManagerCrossChain, FundManagerCrossChainEvents} from "@interfaces/eth/IFundManagerCrossChain.sol";

/**
 * @title FundManagerCrossChain
 * @notice Realizes the virtual ledger for cross-chain transactions (e.g. Zcash ZEC).
 * Tracks the virtual balance for buyers and prevents transaction double-spending via txHash checking.
 */
contract FundManagerCrossChain is ModifierV2, IFundManagerCrossChain, FundManagerCrossChainEvents {
    // Replay protection: txHash => processed status
    mapping(string => bool) private _processedTxs;

    // Virtual order amounts: boxId => userId => accumulated virtual amount
    mapping(uint256 => mapping(bytes32 => uint256)) private _virtualOrderAmounts;

    constructor(address addrManager_) ModifierV2(addrManager_) {}

    /**
     * @notice Records a cross-chain payment.
     * @dev Only callable by registered project contracts (like BuyExecutor).
     */
    function recordPayment(
        uint256 boxId_,
        bytes32 userId_,
        uint256 amount_,
        string calldata chainToken_,
        string calldata txHash_
    ) external override onlyProjectContract {
        require(bytes(txHash_).length > 0, "Empty tx hash");
        require(!_processedTxs[txHash_], "Tx hash already processed");

        _processedTxs[txHash_] = true;
        _virtualOrderAmounts[boxId_][userId_] += amount_;

        emit CrossChainPaymentRecorded(boxId_, userId_, amount_, chainToken_, txHash_);
    }

    /**
     * @notice Clears the virtual payment record after completion or refund.
     * @dev Only callable by registered project contracts.
     */
    function clearPayment(
        uint256 boxId_,
        bytes32 userId_
    ) external override onlyProjectContract {
        uint256 amount = _virtualOrderAmounts[boxId_][userId_];
        if (amount > 0) {
            _virtualOrderAmounts[boxId_][userId_] = 0;
            emit CrossChainPaymentCleared(boxId_, userId_, amount);
        }
    }

    /**
     * @notice Getter for virtual order amount.
     */
    function getVirtualAmount(
        uint256 boxId_,
        bytes32 userId_
    ) external view override returns (uint256) {
        return _virtualOrderAmounts[boxId_][userId_];
    }

    /**
     * @notice Replay protection checking.
     */
    function isTxProcessed(
        string calldata txHash_
    ) external view override returns (bool) {
        return _processedTxs[txHash_];
    }
}
