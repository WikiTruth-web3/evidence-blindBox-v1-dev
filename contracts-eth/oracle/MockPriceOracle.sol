// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IPriceOracle} from "./IPriceOracle.sol";
import {Modifier01} from "../modifier/Modifier01.sol";

/**
 * @title MockPriceOracle
 * @notice A mock price oracle for local testing on Hardhat
 */
contract MockPriceOracle is IPriceOracle, Modifier01 {
    // Mapping: tokenA => tokenB => price (with 18 decimals)
    mapping(address => mapping(address => uint256)) private _prices;

    event PriceSet(address indexed tokenA, address indexed tokenB, uint256 price);

    constructor()  {}

    /**
     * @notice Set exchange rate of tokenA to tokenB
     * @param tokenA_ The source token address
     * @param tokenB_ The target token address
     * @param price_ The price with 18 decimal places precision
     */
    function setPrice(
        address tokenA_,
        address tokenB_,
        uint256 price_
    ) external onlyAdmin {
        _prices[tokenA_][tokenB_] = price_;
        emit PriceSet(tokenA_, tokenB_, price_);
    }

    /**
     * @notice Get exchange rate of tokenA to tokenB
     */
    function getPrice(
        address tokenA_,
        address tokenB_
    ) external view override returns (uint256) {
        if (tokenA_ == tokenB_) {
            return 1e18;
        }
        uint256 price = _prices[tokenA_][tokenB_];
        if (price == 0) revert("Oracle: price not set");
        return price;
    }
}
