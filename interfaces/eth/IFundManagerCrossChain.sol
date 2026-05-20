// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

interface FundManagerCrossChainEvents {
    event CrossChainPaymentRecorded(
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

interface IFundManagerCrossChain is FundManagerCrossChainEvents {
    function setAddress() external;

    function recordPayment(
        uint256 boxId_,
        bytes32 userId_,
        uint256 amount_,
        string calldata chainToken_,
        string calldata txHash_
    ) external;

    function clearPayment(uint256 boxId_, bytes32 userId_) external;

    function getVirtualAmount(
        uint256 boxId_,
        bytes32 userId_
    ) external view returns (uint256);

    function isTxProcessed(string calldata txHash_) external view returns (bool);
}
