// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

interface FundManagerCrossChainEvents {
    event CrossChainOrderAmountPaid(
        uint256 indexed boxId,
        bytes32 indexed userId,
        uint256 amount,
        string chainToken,
        string txHash
    );

    event CrossChainPaymentCleared(
        uint256 indexed boxId,
        bytes32 indexed userId,
        uint256 amount
    );
}

/**
 * @title IFundManagerCrossChain
 * @notice Interface for FundManagerCrossChain contract, tracking virtual balances and external tx hashes.
 */
interface IFundManagerCrossChain {
    /**
     * @notice Record a cross-chain payment
     * @param boxId_ BlindBox ID
     * @param userId_ User ID of the buyer
     * @param amount_ Payment amount in virtual representation
     * @param chainToken_ The external chain and token name (e.g. "Zcash-ZEC")
     * @param txHash_ The external transaction hash
     */
    function recordPayment(
        uint256 boxId_,
        bytes32 userId_,
        uint256 amount_,
        string calldata chainToken_,
        string calldata txHash_
    ) external;

    /**
     * @notice Clear a payment record upon order completion or refund
     * @param boxId_ BlindBox ID
     * @param userId_ User ID of the buyer
     */
    function clearPayment(uint256 boxId_, bytes32 userId_) external;

    /**
     * @notice Get virtual payment amount of a buyer for a specific BlindBox
     */
    function getVirtualAmount(
        uint256 boxId_,
        bytes32 userId_
    ) external view returns (uint256);

    /**
     * @notice Check if an external transaction hash has already been processed (replay protection)
     */
    function isTxProcessed(string calldata txHash_) external view returns (bool);
}
