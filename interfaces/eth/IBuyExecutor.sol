// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

/**
 * @title IBuyExecutor
 * @notice BuyExecutor contract interface.
 */
interface IBuyExecutor {
    function setContracts() external;

    function buyWithExecutor(
        uint256 boxId_,
        bytes32 buyerUserId_,
        uint256 amount_,
        string calldata chainToken_,
        string calldata txHash_
    ) external;

    function bidWithExecutor(
        uint256 boxId_,
        bytes32 buyerUserId_,
        string calldata chainToken_,
        uint256[] calldata amounts_,
        string[] calldata txHashes_
    ) external;

    // function executor() external view returns (address);
}
