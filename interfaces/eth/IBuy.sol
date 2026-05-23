// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

/**
 * @title IBuy
 * @notice Buyer contract interface, defining all externally exposed functions and events
 * @dev This interface serves as the top-level constraint for the Exchange contract, ensuring consistency between interface and implementation
 */
interface IBuy {
    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setCoreContracts() external;
    // =====================================================================================
    //                                          Buying Functions
    // =====================================================================================

    /**
     * @notice Buy a box
     * @param boxId_ Box ID
     */
    function buy(uint256 boxId_) external;

    /**
     * @notice Place a bid on an auction
     * @param boxId_ Box ID
     */
    function bid(uint256 boxId_) external;

    /**
     * @notice Calculate payment amount for a bid
     * @param boxId_ Box ID
     * @return Payment amount required
     */
    function calcPayMoney(uint256 boxId_) external view returns (uint256);

    // =====================================================================================
}
