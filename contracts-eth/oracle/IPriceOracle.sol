// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

/**
 * @title IPriceOracle
 * @notice Interface for retrieving exchange rates between tokens
 */
interface IPriceOracle {
    /**
     * @notice Get exchange rate of tokenA relative to tokenB
     * @param tokenA_ The source token address
     * @param tokenB_ The target token address
     * @return price The exchange rate with 18 decimal places precision.
     *         e.g., 1 unit of tokenA = price / 1e18 units of tokenB
     */
    function getPrice(address tokenA_, address tokenB_) external view returns (uint256 price);
}
