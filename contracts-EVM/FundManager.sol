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
import {I_Swap} from "./dex/interfaceSwap.sol";

import {FundManagerBase} from "./abstract/FundManagerBase.sol";

/**
 * @title FundManager
 * @dev Fund management contract that supports multiple tokens
 * v1.6 upgraded version of FundManager, extending existing FundManager to support multi-token transactions
 */

contract FundManager is FundManagerBase, IFundManager{
    using SafeERC20 for IERC20;

    // ====================================================================================================================
    
    error EmptyList();
    error WithdrawError();
    error ApprovalFailed();

    // =======================================================================================


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

    function setAddress() external checkSetCaller {
        _setAddress();
    }

    // ====================================================================================================================
    // Fund Pay Functions
    function _approveToken(address token, address spender ) private{
        // Authorize the maximum possible amount of tokens, effectively an "unlimited" authorization
        bool success = IERC20(token).approve(spender, type(uint256).max);
        if (!success) revert ApprovalFailed();
    }

    /**
     * @dev Pay order amount
     * @param boxId_ TruthBox ID
     * @param buyer_ Buyer address
     * @param amount_ Amount to deposit
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
        // Directly assign the service fee to the DAO fund manager contract
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
        address swapContract = ADDR_MANAGER.swapContract();

        uint256 amountIn_token = (amount_* totalRate) / 1000;
        uint256 amountOut_official;
        
        if (token_ != officialToken) {
            
            // Authorize the maximum possible amount of tokens to SwapRouter
            if (IERC20(token_).allowance(address(this), swapContract) < amount_) {
                _approveToken(token_, swapContract);
            }
            /**
             * @dev SwapContract
             * This is using SwapContract to trade
             * Only applicable to local test network, actual deployment needs to use SwapRouter (Uniswap V3)
             */
            amountOut_official = I_Swap(swapContract).getSwapAmountOut(token_, officialToken, amount_);
            // Reset the price of TruthBox
            TRUTH_BOX.setPrice(boxId_, amountOut_official);
            amountOut_official = (amountOut_official * totalRate) / 1000;
            amountIn_token = I_Swap(swapContract).swapForExact(token_, officialToken, amountOut_official);
            
            
        } else {
            // If token is official token, calculate allocation directly, and amountOut and amountIn are equal
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

            // Directly assign the service fee to the DAO fund manager contract
            IERC20(officialToken).safeTransfer(
                ADDR_MANAGER.daoFundManager(), 
                (amountOut_official - sellerRewards - completerRewards)
            );
        }

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

    /**
     * @dev Get order amount
     * @param boxId_ TruthBox ID
     * @param user_ User address
     * @return Order amount
     */
    function orderAmounts(
        uint256 boxId_,
        address user_
    ) external view returns (uint256) {
        return _orderAmounts[boxId_][user_];
    }

    /**
     * @dev Get helper reward amount
     * @param token_ Token address
     * @param helper_ Helper address
     * @return Helper reward amount
     */
    function helperRewardAmounts(
        address token_,
        address helper_
    ) external view returns (uint256) {
        // if (msg.sender != address(EXCHANGE)) revert InvalidCaller();
        return _helperRewrdAmounts[helper_][token_];
    }

    /**
     * @dev Get minter reward amount
     * @param token_ Token address
     * @param minter_ Minter address
     * @return Minter reward amount
     */
    function minterRewardAmounts(
        address token_,
        address minter_
    ) external view returns (uint256) {
        return _minterRewardAmounts[minter_][token_];
    }

    // --------------------------------------------------

    


}
