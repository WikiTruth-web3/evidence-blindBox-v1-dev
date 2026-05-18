// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface I_Swap {

    // function setAddress() external;

    // External functions
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
    function reserve0() external view returns (uint256);
    function reserve1() external view returns (uint256);
    function totalLiquidity() external view returns (uint256);
    function liquidity(address account) external view returns (uint256);
    
    // Set the token pair
    function setToken(address _token0, address _token1) external;
    
    // Add liquidity
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 liquidityMinted);
    
    // Remove liquidity
    function removeLiquidity(uint256 liquidityAmount) external returns (uint256 amount0, uint256 amount1);
    
    // Get the swap price: the number of token0 exchanged for token1
    function getSwapAmount0For1(uint256 amountIn) external view returns (uint256);
    
    // Get the swap price: the number of token1 exchanged for token0
    function getSwapAmount1For0(uint256 amountIn) external view returns (uint256);

    function swapExact(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut); 
    function getSwapAmountIn(address tokenIn, address tokenOut, uint256 amountOut) external view returns (uint256);
    function getSwapAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);
    function swapForExact(address tokenIn, address tokenOut, uint256 amountOut) external returns (uint256 amountIn);
} 

