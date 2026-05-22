// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {ModifierV2} from "./modifier/ModifierV2.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "./abstract/Pausable.sol";
import {IFundManagerVirtual, FundManagerVirtualEvents} from "@interfaces/eth/IFundManagerVirtual.sol";

/**
 * @title FundManagerVirtual
 * @notice Realizes the virtual ledger for cross-chain transactions (e.g. Zcash ZEC).
 * Tracks the virtual balance for buyers and prevents transaction double-spending via txHash checking.
 */
contract FundManagerVirtual is ModifierV2, ReentrancyGuard, Pausable, IFundManagerVirtual, FundManagerVirtualEvents {

    error EmptyTxHash();
    error TxHashAlreadyProcessed();
    // Replay protection: txHash => processed status
    mapping(string => bool) private _processedTxs;

    struct paymentData {
        string _chain;
        string _token;
        string amount;
    }

    // Virtual order amounts: boxId => userId => accumulated virtual amount
    mapping(uint256 boxId => mapping(bytes32 userId => orderData)) private _virtualOrderAmounts;

    constructor(address addrManager_) ModifierV2(addrManager_) {}

    function _record(
        uint256 boxId_,
        bytes32 userId_,
        string calldata chain_,
        string calldata token_,
        uint256 amount_
    ) internal {
        if (bytes(chain_).length == 0) revert EmptyChain();
        if (bytes(token_).length == 0) revert EmptyToken();
        if (amount_ == 0) revert EmptyAmount();

        if (bytes(_chain).length == 0) {
            _virtualOrderAmounts[boxId_][userId_]._chain = chain_;
        }

        if (bytes(_token).length == 0) {
            _virtualOrderAmounts[boxId_][userId_]._token = token_;
        }

        _virtualOrderAmounts[boxId_][userId_]._amount += amount_;
        emit CrossChainPayment(boxId_, userId_,  chain, token_,amount_);

    }

    /**
     * @notice Records a cross-chain payment.
     * @dev Only callable by registered project contracts (like BuyExecutor).
     */
    function recordPayment(
        uint256 boxId_,
        bytes32 userId_,
        uint256 amount_,
        string calldata chain_,
        string calldata token_,
        string[] calldata txHashList_
    ) external{
        if (txHashList_.length == 0) revert EmptyTxHash();

        for (i; i< txHashList_.length; i++) {
            if (bytes(txHash_).length == 0) revert EmptyTxHash();
            if (_processedTxs[txHash_]) revert TxHashAlreadyProcessed();

            _processedTxs[txHash_] = true;
        }
        _record(boxId_, userId_,  chain, token_,amount_);
    }

    /**
     * @notice Clears the virtual payment record after completion or refund.
     * @dev Only callable by registered project contracts.
     */
    function _clearPayment(
        uint256 boxId_,
        bytes32 userId_
    ) internal {
        uint256 amount = _virtualOrderAmounts[boxId_][userId_]._amount;
        _virtualOrderAmounts[boxId_][userId_]._amount = 0;
        emit CrossChainPaymentCleared(boxId_, userId_, amount);
    }

    function _checkPaymentAmount(
        uint256 boxId_,
        bytes32 userId_
    ) internal {
        uint256 amount = _virtualOrderAmounts[boxId_][userId_]._amount;
        if (amount == 0) {
            revert AmountIsZero();
        }
    }

    function clearPayment(
        uint256 boxId_,
        bytes32 userId_
    ) external nonReentrant onlyAdminExecutor{
        bytes32 buyerId = EXCHANGE.buyerIdOf(boxId_);

        if(buyerId != userId_) revert UserIdError();
        _checkPaymentAmount(boxId_,userId_);
        _clearPayment(boxId_, userId_);

        // TODO  NOTE need Orcale Contract interface ,get the price.

        FUND_MANAGER.allocationRewards(boxId_,msg.sender, amount);

    }

    // ======================================================================

        /**
     * @dev Withdraw order amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of BlindBox IDs
     * @param type_ Type of withdrawal, either 0(order) or 1(refund)
     */
    function _withdrawOrderAmounts(
        uint256 boxId_,
        FundsType type_
    ) internal nonReentrant whenNotPaused {
        IExchange exchange = EXCHANGE;
        // erc2771 - msg.sender is the real caller
        bytes32 userId = USER_MANAGER.getUserId(msg.sender);

        // Process refunds for each box
        bytes32 buyerId = exchange.buyerIdOf(boxId);

        if (type_ == FundsType.Order) {
            // Cannot be the current buyer
            if (userId == buyerId) revert InvalidCaller();
        } else if (type_ == FundsType.Refund) {
            // The caller must be the buyer and the refund must be permitted
            if (
                userId != buyerId || 
                !exchange.refundPermit(boxId)
            ) {
                revert WithdrawError();
            }
            BLIND_BOX.setStatus(boxId_, Status.Published);
        }
        _checkPaymentAmount(boxId_,userId);
        _clearPayment(boxId_, userId);

    }

    /**
     * @dev Withdraw order amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of BlindBox IDs
     */
    function withdrawOrderAmounts(
        uint256 boxId_
    ) external {
        _withdrawOrderAmounts(boxId_, FundsType.Order);
    }

    /**
     * @dev Withdraw refund amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of BlindBox IDs
     */
    function withdrawRefundAmounts(
        uint256 boxId_
    ) external {
        _withdrawOrderAmounts(boxId_, FundsType.Refund);
    }


    // =================================================================

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
