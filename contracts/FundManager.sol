// SPDX-License-Identifier: GPL-2.0-or-later

/**
 *         ██╗    ██╗██╗██╗  ██╗██╗    ████████╗██████╗ ██╗   ██╗████████╗██╗  ██╗
 *         ██║    ██║██║██║ ██╔╝██║    ╚══██╔══╝██╔══██╗██║   ██║╚══██╔══╝██║  ██║
 *         ██║ █╗ ██║██║█████╔╝ ██║       ██║   ██████╔╝██║   ██║   ██║   ███████║
 *         ██║███╗██║██║██╔═██╗ ██║       ██║   ██╔══██╗██║   ██║   ██║   ██╔══██║
 *         ╚███╔███╔╝██║██║  ██╗██║       ██║   ██║  ██║╚██████╔╝   ██║   ██║  ██║
 *          ╚══╝╚══╝ ╚═╝╚═╝  ╚═╝╚═╝       ╚═╝   ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝   
 *
 *  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
 *  ┃                        Website: https://wikitruth.eth.limo/                         ┃
 *  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
 */

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {Pausable} from "../openzeppelin/contracts/utils/Pausable.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import {ITruthBox} from "@wikitruth-v1/interfaces/ITruthBox.sol";
import {IFundManager} from "@wikitruth-v1/interfaces/IFundManager.sol";
import {IExchange} from "@wikitruth-v1/interfaces/IExchange.sol";

import {ISwapRouter} from "./interfaces2/ISwapRouter.sol";
import {IQuoter} from "./interfaces2/IQuoter.sol";

import {FundManagerBase} from "./abstract/FundManagerBase.sol";

/**
 * @title FundManager
 * @notice Fund management contract that supports multiple tokens
 * @dev v1.6 upgraded version of FundManager, extending existing FundManager to support multi-token transactions
 * Inherits IFundManager interface to ensure consistency between interface and implementation
 */

contract FundManager is FundManagerBase, IFundManager {
    using SafeERC20 for IERC20;

    // ====================================================================================================================
    
    error EmptyList();
    // error InsufficientFundAmount();
    error WithdrawError();
    error ApprovalFailed();



    /// @dev Total reward amounts
    mapping(address token => uint256) internal _totalRewardAmounts;

    // Order amounts mapping (by token recorded by EXCHANGE contract, boxId and buyer address)
    mapping(uint256 boxId => mapping(address buyer => uint256)) private _orderAmounts;

    // Minter reward amounts for each token (only two types: token recorded by EXCHANGE contract, and official token)
    mapping(address minter => mapping(address token  => uint256)) private _minterRewardAmounts;

    // User reward amounts (using official token)
    mapping(address helper => mapping(address token => uint256)) private _helperRewrdAmounts;

    // ====================================================================================================================

    constructor(address addrManager_) FundManagerBase(addrManager_){

    }

    // ==========================================================================================================
    //                                          Override Functions
    // ==========================================================================================================
    
    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setAddress() external checkSetCaller {
        _setAddress();
    }

    // ====================================================================================================================
    
    /**
     * @dev Pay order amount
     * @param boxId_ TruthBox ID
     * @param buyer_ Buyer address
     * @param amount_ Amount to pay
     */
    function payOrderAmount(
        uint256 boxId_,
        address buyer_,
        uint256 amount_
    ) external onlyProjectContract {
        address token = EXCHANGE.acceptedToken(boxId_);

        IERC20(token).safeTransferFrom(buyer_, address(this), amount_);

        _orderAmounts[boxId_][buyer_] += amount_;

        uint256 userId = USER_ID.getUserId(buyer_);
        emit OrderAmountPaid(boxId_, userId, token, amount_);
    }

    /**
     * @dev Pay confidentiality fee
     * @param boxId_ TruthBox ID
     * @param sender_ Sender address
     * @param amount_ Amount to pay
     */
    function payConfidentialityFee(
        uint256 boxId_,
        address sender_,
        uint256 amount_
    ) external onlyProjectContract {
        address officialToken = ADDR_MANAGER.officialToken();
        IERC20(officialToken).transferFrom(sender_, address(this), amount_);

        address minter = TRUTH_BOX.minterOf(boxId_);
        uint256 serviceFee = (amount_ * _serviceFeeRate) / 1000;
        uint256 minterReward = amount_ - serviceFee;

        unchecked {
            _totalRewardAmounts[officialToken] += amount_;
            _minterRewardAmounts[minter][officialToken] += minterReward;
        }
        // Assign service fee to DAO fund manager
        IERC20(officialToken).safeTransfer(ADDR_MANAGER.daoFundManager(), serviceFee);

        emit RewardsAdded(boxId_, officialToken, amount_, RewardType.Total);
        emit RewardsAdded(boxId_, officialToken, minterReward, RewardType.Minter);
    }

    // ====================================================================================================================
    // Reward Allocation Functions

    /**
     * @dev Allocate rewards
     * @param boxId_ TruthBox ID
     */
    function allocationRewards(uint256 boxId_) external onlyProjectContract {
        address buyer = EXCHANGE.buyerOf(boxId_);
        address minter = TRUTH_BOX.minterOf(boxId_);
        address token = EXCHANGE.acceptedToken(boxId_);

        uint256 amount = _orderAmounts[boxId_][buyer];
        if (amount == 0) revert AmountIsZero();
        
        // Clear the original token order amount
        _orderAmounts[boxId_][buyer] = 0;
        _calculateAllocation(boxId_, minter, amount, token);
        
        // Record total reward amount
        _totalRewardAmounts[token] += amount;
        
        emit RewardsAdded(boxId_, token, amount, RewardType.Total);
    }


    /**
     * @dev Internal method: Calculate allocation
     * @param boxId_ TruthBox ID
     * @param amount_ Amount
     * @param token_ Token address
     */
    function _calculateAllocation(
        uint256 boxId_,
        address minter_,
        uint256 amount_,
        address token_
    ) private {
        
        // Get various rates and roles
        address completer = EXCHANGE.completerOf(boxId_);
        address seller = EXCHANGE.sellerOf(boxId_);
        uint8 sellerRate;
        uint8 completerRate;
        // Calculate rewards

        if (completer != address(0)) {
            completerRate = _helperRewardRate;
        }
        // If there is a seller, it means the token is the original token
        if (seller != address(0)) {
            sellerRate = _helperRewardRate;
        }

        uint8 totalRate = _serviceFeeRate + sellerRate + completerRate;

        address officialToken = ADDR_MANAGER.officialToken();
        
        uint256 amountIn_token;
        uint256 amountOut_official;
        
        if (token_ != officialToken) {
            // Add extra fee rate to total rate
            totalRate += _extraFeeRate;
            // If token is not official token, it needs to be swapped
            (amountIn_token, amountOut_official) = _swap(
                boxId_, 
                token_, 
                officialToken, 
                amount_, 
                totalRate
            );

        } else {
            // If token is official token, calculate allocation directly, and amountOut and amountIn are equal
            amountIn_token = (amount_* totalRate) / 1000;
            amountOut_official = amountIn_token;
        }

        unchecked {
            // Calculate allocation amounts
            uint256 sellerRewards = (amountOut_official * sellerRate) / totalRate;
            uint256 completerRewards = (amountOut_official * completerRate) / totalRate;
        
            if (completerRewards > 0) {
                _helperRewrdAmounts[completer][officialToken] += completerRewards;
                emit RewardsAdded(boxId_, officialToken, completerRewards, RewardType.Completer);
            }
            // If there is a seller, it means the token is the original token
            if (sellerRewards > 0) {
                _helperRewrdAmounts[seller][officialToken] += sellerRewards;
                emit RewardsAdded(boxId_, officialToken, sellerRewards, RewardType.Seller);
            }
            // Update minter rewards (using original token)
            _minterRewardAmounts[minter_][token_] += (amount_ - amountIn_token);
            emit RewardsAdded(boxId_, token_, (amount_ - amountIn_token), RewardType.Minter);

            // Assign service fee to DAO fund manager
            IERC20(officialToken).safeTransfer(
                ADDR_MANAGER.daoFundManager(), 
                (amountOut_official - sellerRewards - completerRewards)
            );
        }

    }

    /**
     * @dev Internal method: Swap
     * @param boxId_ TruthBox ID
     * @param tokenIn_ Token in
     * @param tokenOut_ Token out
     * @param amount_ Amount
     * @param totalRate_ Total rate
     * @return amountIn_ Amount in
     * @return amountOut_ Amount out
     */
    function _swap(
        uint256 boxId_,
        address tokenIn_, 
        address tokenOut_, 
        uint256 amount_, 
        uint8 totalRate_
    ) private returns (uint256, uint256) {
        address swapContract = SWAP_CONTRACT;
        address quoter = ADDR_MANAGER.quoter();

        // check allowance and approve
        if (IERC20(tokenIn_).allowance(address(this), swapContract) < amount_) {
            _approveToken(tokenIn_, swapContract);
        }
        
        // step 1: calculate the amount of tokenOut that can be exchanged for tokenIn
        // using quoter to calculate the amount of tokenOut that can be exchanged for tokenIn
        uint256 totalAmountOut = IQuoter(quoter).quoteExactInputSingle(
            tokenIn_,
            tokenOut_,
            3000, // 0.3% service fee
            amount_, // using the exact amount of tokenIn
            0 // no price limit
        );
        
        // step 2: calculate the amount of tokenOut that can be exchanged for tokenIn
        uint256 amountOut_ = (totalAmountOut * totalRate_) / 1000;

        // step 3: execute the swap, using exactOutputSingle to exchange the exact amount of tokenOut
        uint256 amountIn_ = ISwapRouter(swapContract).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenIn_,
                tokenOut: tokenOut_,
                fee: 3000, // 0.3% service fee
                recipient: address(this),
                deadline: block.timestamp + 300, 
                amountOut: amountOut_, // exact amount of tokenOut
                amountInMaximum: amount_, 
                sqrtPriceLimitX96: 0 
            })
        );

        // step 4: reset the price of TruthBox
        // Because the confidentiality fee must be in the officialToken, 
        // so we need to reset the price of TruthBox
        TRUTH_BOX.setPrice(boxId_, totalAmountOut);

        return (amountIn_, amountOut_);
    }

    // Fund Deposit Functions
    function _approveToken(address token, address spender ) private{
        // Authorize the maximum possible amount of tokens, effectively an "unlimited" authorization
        bool success = IERC20(token).approve(spender, type(uint256).max);
        if (!success) revert ApprovalFailed();
    }

    // ====================================================================================================================
    // Withdrawal Functions
    /**
     * @dev Withdraw order amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of TruthBox IDs
     * @param type_ Type of withdrawal, either 0(order) or 1(refund)
     */
    function _withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_,
        FundsType type_
    ) private nonReentrant whenNotPaused {
        if (list_.length == 0) revert EmptyList();
        uint256 amount;
        IExchange exchange = EXCHANGE;
        // Process refunds for each box
        for (uint256 i = 0; i < list_.length; i++) {
            uint256 boxId = list_[i];
            uint256 orderAmount = _orderAmounts[boxId][msg.sender];
            address buyer = exchange.buyerOf(boxId);
            if (orderAmount == 0) {
                revert AmountIsZero();
            }

            if (type_ == FundsType.Order) {
                // Cannot be the current buyer
                if (msg.sender == buyer) revert InvalidCaller();
            } else if (type_ == FundsType.Refund) {
                // The caller must be the buyer and the refund must be permitted
                if (
                    msg.sender != buyer ||
                    !exchange.refundPermit(boxId)
                ) {
                    revert WithdrawError();
                }
                exchange.setRefundPermit(boxId, false);
            } 
            
            // Confirm token type matches
            if (exchange.acceptedToken(boxId) != token_) {
                revert WithdrawError();
            }
            unchecked {
                amount += orderAmount;
            }
            _orderAmounts[boxId][msg.sender] = 0;
        }
        
        // Execute refund
        IERC20(token_).safeTransfer(msg.sender, amount);

        uint256 userId = USER_ID.getUserId(msg.sender);
        emit OrderAmountWithdraw(list_, token_, userId, amount, type_);
    }

    /**
     * @dev Withdraw order amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of TruthBox IDs
     */
    function withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_
    ) external {
        _withdrawOrderAmounts(token_, list_, FundsType.Order);
    }

    /**
     * @dev Withdraw refund amounts (Refund or Order , for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of TruthBox IDs
     */
    function withdrawRefundAmounts(
        address token_,
        uint256[] calldata list_
    ) external {
        _withdrawOrderAmounts(token_, list_, FundsType.Refund);
    }

    //--------------------------------------------------

    /**
     * @dev Withdraw other reward amounts (official token only)
     * @param token_ Token address
     */
    function withdrawHelperRewards(address token_) external nonReentrant whenNotPaused{

        uint256 amount = _helperRewrdAmounts[msg.sender][token_];
        if (amount == 0) {
            revert AmountIsZero();
        } 
        _helperRewrdAmounts[msg.sender][token_] = 0;
        IERC20(token_).safeTransfer(msg.sender, amount);

        uint256 userId = USER_ID.getUserId(msg.sender);
        emit HelperRewrdsWithdraw(userId , token_, amount);
    }

    /**
     * @dev Withdraw minter rewards
     * @param token_ Token address
     */
    function withdrawMinterRewards(address token_) external nonReentrant whenNotPaused {
        uint256 amount = _minterRewardAmounts[msg.sender][token_];
        if (amount == 0) {
            revert AmountIsZero();
        }
        // Zero out reward amount
        _minterRewardAmounts[msg.sender][token_] = 0;
        // Execute safeTransfer
        IERC20(token_).safeTransfer(msg.sender, amount);

        uint256 userId = USER_ID.getUserId(msg.sender);
        emit MinterRewardsWithdraw(userId, token_, amount);
    }

    // ====================================================================================================================
    //                    Query Functions
    // ====================================================================================================================

    /**
     * @dev Get order amount
     * @param boxId_ TruthBox ID
     * @param user_ User address
     * @return Order amount
     * This is the function for project contract to interact with, 
     * so it needs to verify that msg.sender is the project contract!
     * Cannot be deleted!
     */
    function orderAmounts(
        uint256 boxId_,
        address user_
    ) external onlyProjectContract view returns (uint256) {
        return _orderAmounts[boxId_][user_];
    }

    /**
     * @notice verify the sender is correct
     * @param siweToken_ The siwe token of the user 
     * @return The sender of the function
     * In sapphire, msg.sender is the zero address, so we need to get sender through siweToken_
     */
    function _msgSender(bytes memory siweToken_) internal view returns (address) {
        address sender = msg.sender;
        if (sender == address(0)) {
            sender = SIWE_AUTH.getMsgSender(siweToken_);
        }
        return sender;
    }

    /**
     * @dev Get order amount
     * @param boxId_ TruthBox ID
     * @param siweToken_ User siwe token
     * @return Order amount
     */
    function orderAmounts(
        uint256 boxId_,
        bytes memory siweToken_
    ) external onlyProjectContract view returns (uint256) {
        address sender = _msgSender(siweToken_);
        return _orderAmounts[boxId_][sender];
    }

    /**
     * @dev Get minter reward amount
     * @param token_ Token address
     * @param siweToken_ User siwe token
     * @return Minter reward amount
     */
    function minterRewardAmounts(
        address token_,
        bytes memory siweToken_
    ) external view returns (uint256) {
        address sender = _msgSender(siweToken_);
        return _minterRewardAmounts[sender][token_];
    }

    /**
     * @dev Get helper reward amount
     * @param token_ Token address
     * @param siweToken_ User siwe token
     * @return Helper reward amount
     */
    function helperRewardAmounts(
        address token_,
        bytes memory siweToken_
    ) external view returns (uint256) {
        address sender = _msgSender(siweToken_);
        return _helperRewrdAmounts[sender][token_];
    }

    // ===================================================================================

    /**
     * @dev Get total reward amount
     * @param token_ Token address
     * @return Total reward amount
     */
    function totalRewardAmounts(address token_) public view returns (uint256) {
        return _totalRewardAmounts[token_];
    }

    // ----------------------------------------------------------------
    //                      Debugging Functions
    // ----------------------------------------------------------------
    // TODO This is the function for debugging, not used in the production environment！！！

    // /**
    //  * @dev Get order amount
    //  * @param boxId_ TruthBox ID
    //  * @param user_ User address
    //  * @return Order amount
    //  */
    // function orderAmounts(
    //     uint256 boxId_,
    //     address user_
    // ) external view returns (uint256) {
    //     return _orderAmounts[boxId_][user_];
    // }

    // /**
    //  * @dev Get helper reward amount
    //  * @param token_ Token address
    //  * @param helper_ Helper address
    //  * @return Helper reward amount
    //  */
    // function helperRewardAmounts(
    //     address token_,
    //     address helper_
    // ) external view returns (uint256) {
    //     return _helperRewrdAmounts[helper_][token_];
    // }

    // /**
    //  * @dev Get minter reward amount
    //  * @param token_ Token address
    //  * @param minter_ Minter address
    //  * @return Minter reward amount
    //  */
    // function minterRewardAmounts(
    //     address token_,
    //     address minter_
    // ) external view returns (uint256) {
    //     return _minterRewardAmounts[minter_][token_];
    // }

    // --------------------------------------------------

    


}
