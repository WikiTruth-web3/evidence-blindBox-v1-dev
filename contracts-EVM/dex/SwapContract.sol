// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Symbol: TSWAP
contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    
    error ReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) {
            revert ReentrantCall();
        }
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * @title SwapContract(test)
 * @dev A simple token swap contract that allows users to swap between two tokens
 * v1.6 upgraded version of SwapContract, extending existing SwapContract to support multi-token transactions
 * NOTE: This contract is not production-ready and is for testing purposes only.
 */

contract SwapContract is ReentrancyGuard {

    error NotAdmin();
    error ZeroAddress();
    error IdenticalAddresses();
    error InsufficientInputAmount();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();

    // ============================================================================
    using SafeERC20 for IERC20;

    address internal ADMIN;
    
    // The two tokens in the pair
    IERC20 public token0;
    IERC20 public token1;

    // The amount of tokens in the pool
    uint256 public reserve0;
    uint256 public reserve1;

    // The total supply of the liquidity token
    uint256 public totalLiquidity;
    
    // The user's liquidity share
    mapping(address => uint256) public liquidity;

    // The minimum liquidity value to prevent price manipulation when adding liquidity for the first time
    uint256 private constant MINIMUM_LIQUIDITY = 1000;

    // ============================================================================
    // Event definitions
    event AddLiquidity(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidityMinted);
    event RemoveLiquidity(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidityBurned);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isToken0In);

    constructor() {
        ADMIN = msg.sender;
        
    }
    // ============================================================================


    // ============================================================================

    function setToken(address _token0, address _token1) public {
        if(msg.sender != ADMIN) revert NotAdmin();

        if (_token0 == address(0) || _token1 == address(0)) {
            revert ZeroAddress();
        }
        if (_token0 == _token1) {
            revert IdenticalAddresses();
        }
        
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);

    }

    function addLiquidity(uint256 amount0, uint256 amount1) external nonReentrant returns (uint256 liquidityMinted) {
        if (amount0 == 0 || amount1 == 0) {
            revert InsufficientInputAmount();
        }

        // Adding liquidity for the first time
        if (totalLiquidity == 0) {
            liquidityMinted = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            totalLiquidity = MINIMUM_LIQUIDITY;
            liquidity[address(0)] = MINIMUM_LIQUIDITY; // Lock the minimum liquidity
        } else {
            // Not the first time adding, keep the price unchanged
            uint256 liquidity0 = (amount0 * totalLiquidity) / reserve0;
            uint256 liquidity1 = (amount1 * totalLiquidity) / reserve1;
            liquidityMinted = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            
            if (liquidityMinted == 0) {
                revert InsufficientLiquidityMinted();
            }
        }

        // Safe transfer tokens
        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);

        // Update the reserves
        reserve0 += amount0;
        reserve1 += amount1;
        
        // Increase the user's liquidity share
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        emit AddLiquidity(msg.sender, amount0, amount1, liquidityMinted);
        return liquidityMinted;
    }

    function removeLiquidity(uint256 liquidityAmount) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        if (liquidityAmount == 0) {
            revert InsufficientLiquidityBurned();
        }
        
        if (liquidity[msg.sender] < liquidityAmount) {
            revert InsufficientLiquidity();
        }
        
        // Calculate the amount of tokens that can be obtained
        amount0 = (liquidityAmount * reserve0) / totalLiquidity;
        amount1 = (liquidityAmount * reserve1) / totalLiquidity;
        
        if (amount0 == 0 || amount1 == 0) {
            revert InsufficientLiquidityBurned();
        }

        // Reduce the user's liquidity share
        liquidity[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;

        // Transfer out tokens
        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);

        // Update the reserves
        reserve0 -= amount0;
        reserve1 -= amount1;

        emit RemoveLiquidity(msg.sender, amount0, amount1, liquidityAmount);
        return (amount0, amount1);
    }

    function swapExact(address tokenIn, address tokenOut, uint256 amountIn) external nonReentrant returns (uint256 amountOut) {
        if (amountIn == 0) {
            revert InsufficientInputAmount();
        }
        
        if (reserve0 == 0 || reserve1 == 0) {
            revert InsufficientLiquidity();
        }
        
        // verify token address
        if (tokenIn == address(0) || tokenOut == address(0)) {
            revert InvalidTokenAddress();
        }
        
        // determine the type of input and output tokens
        bool isToken0In = (tokenIn == address(token0));
        bool isToken1In = (tokenIn == address(token1));
        
        if (!isToken0In && !isToken1In) {
            revert TokenNotInPool();
        }
        
        if ((isToken0In && tokenOut != address(token1)) || 
            (isToken1In && tokenOut != address(token0))) {
            revert TokenNotInPool();
        }
        
        // calculate the output amount
        if (isToken0In) {
            amountOut = getSwapAmount0For1(amountIn);
        } else {
            amountOut = getSwapAmount1For0(amountIn);
        }
        
        if (amountOut == 0) {
            revert InsufficientOutputAmount();
        }
        
        // execute token transfer
        if (isToken0In) {
            // token0 -> token1
            token0.safeTransferFrom(msg.sender, address(this), amountIn);
            token1.safeTransfer(msg.sender, amountOut);
            
            // update the reserves
            reserve0 += amountIn;
            reserve1 -= amountOut;
            
            emit Swap(msg.sender, amountIn, amountOut, true);
        } else {
            // token1 -> token0
            token1.safeTransferFrom(msg.sender, address(this), amountIn);
            token0.safeTransfer(msg.sender, amountOut);
            
            // update the reserves
            reserve1 += amountIn;
            reserve0 -= amountOut;
            
            emit Swap(msg.sender, amountIn, amountOut, false);
        }
        
        return amountOut;
    }

    // Get the swap price: the number of token0 exchanged for token1
    function getSwapAmount0For1(uint256 amountIn) public view returns (uint256) {
        if (amountIn == 0 || reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        
        uint256 amountInWithFee = amountIn * 997;
        return (amountInWithFee * reserve1) / ((reserve0 * 1000) + amountInWithFee);
    }

    // Get the swap price: the number of token1 exchanged for token0
    function getSwapAmount1For0(uint256 amountIn) public view returns (uint256) {
        if (amountIn == 0 || reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        
        uint256 amountInWithFee = amountIn * 997;
        return (amountInWithFee * reserve0) / ((reserve1 * 1000) + amountInWithFee);
    }

    // error definition
    error InvalidTokenAddress();
    error TokenNotInPool();

    // calculate the input amount based on the expected output amount
    function getSwapAmountIn(address tokenIn, address tokenOut, uint256 amountOut) public view returns (uint256) {
        if (amountOut == 0 || reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        
        // verify token address
        if (tokenIn == address(0) || tokenOut == address(0)) {
            return 0;
        }
        
        // determine the type of input and output tokens
        bool isToken0In = (tokenIn == address(token0));
        bool isToken1In = (tokenIn == address(token1));
        
        if (!isToken0In && !isToken1In) {
            return 0; // input token not in pool
        }
        
        if ((isToken0In && tokenOut != address(token1)) || 
            (isToken1In && tokenOut != address(token0))) {
            return 0; // output token not matched
        }
        
        // calculate the input amount based on the token type
        if (isToken0In) {
            // token0 -> token1
            if (amountOut >= reserve1) {
                return 0; // output amount cannot be greater than reserve amount
            }
            
            // fix math calculation: avoid precision loss
            // 公式：amountIn = (amountOut * reserve0 * 1000) / ((reserve1 - amountOut) * 997)
            uint256 numerator = amountOut * reserve0 * 1000;
            uint256 denominator = (reserve1 - amountOut) * 997;
            
            // add 1 to round up, avoid precision loss
            return (numerator + denominator - 1) / denominator;
        } else {
            // token1 -> token0
            if (amountOut >= reserve0) {
                return 0; // output amount cannot be greater than reserve amount
            }
            
            // fix math calculation: avoid precision loss
            // 公式：amountIn = (amountOut * reserve1 * 1000) / ((reserve0 - amountOut) * 997)
            uint256 numerator = amountOut * reserve1 * 1000;
            uint256 denominator = (reserve0 - amountOut) * 997;
            
            // add 1 to round up, avoid precision loss
            return (numerator + denominator - 1) / denominator;
        }
    }
    // calculate the output amount based on the input amount
    function getSwapAmountOut(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256) {
        if (amountIn == 0 || reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        
        if (tokenIn == address(0) || tokenOut == address(0)) {
            return 0;
        }
        
        if (tokenIn == address(token0)) {
            return getSwapAmount0For1(amountIn);
        }
        if (tokenIn == address(token1)) {
            return getSwapAmount1For0(amountIn);
        }
        
        return 0;
    }

    // swap for exact amount
    function swapForExact(address tokenIn, address tokenOut, uint256 amountOut) external nonReentrant returns (uint256 amountIn) {
        if (amountOut == 0) {
            revert InsufficientOutputAmount();
        }
        
        if (reserve0 == 0 || reserve1 == 0) {
            revert InsufficientLiquidity();
        }
        
        // verify token address
        if (tokenIn == address(0) || tokenOut == address(0)) {
            revert InvalidTokenAddress();
        }
        
        // determine the type of input and output tokens
        bool isToken0In = (tokenIn == address(token0));
        bool isToken1In = (tokenIn == address(token1));
        
        if (!isToken0In && !isToken1In) {
            revert TokenNotInPool();
        }
        
        if ((isToken0In && tokenOut != address(token1)) || 
            (isToken1In && tokenOut != address(token0))) {
            revert TokenNotInPool();
        }
        
        // calculate the input amount
        amountIn = getSwapAmountIn(tokenIn, tokenOut, amountOut);
        
        if (amountIn == 0) {
            revert InsufficientInputAmount();
        }
        
        // verify the calculation result (allow small slippage error)
        uint256 actualAmountOut;
        if (isToken0In) {
            actualAmountOut = getSwapAmount0For1(amountIn);
            if (actualAmountOut < amountOut) {
                revert InsufficientOutputAmount();
            }
        } else {
            actualAmountOut = getSwapAmount1For0(amountIn);
            if (actualAmountOut < amountOut) {
                revert InsufficientOutputAmount();
            }
        }
        
        // execute token transfer
        if (isToken0In) {
            // token0 -> token1
            token0.safeTransferFrom(msg.sender, address(this), amountIn);
            token1.safeTransfer(msg.sender, amountOut);
            
            // update the reserves
            reserve0 += amountIn;
            reserve1 -= amountOut;
            
            emit Swap(msg.sender, amountIn, amountOut, true);
        } else {
            // token1 -> token0
            token1.safeTransferFrom(msg.sender, address(this), amountIn);
            token0.safeTransfer(msg.sender, amountOut);
            
            // update the reserves
            reserve1 += amountIn;
            reserve0 -= amountOut;
            
            emit Swap(msg.sender, amountIn, amountOut, false);
        }
        
        return amountIn;
    }

    // Calculate the square root of a number
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
} 



