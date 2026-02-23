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
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITruthBox} from "@wikitruth-v1/interfaces/ITruthBox.sol";
import {IFundManager} from "@wikitruth-v1/interfaces/IFundManager.sol";
import {IExchange} from "@wikitruth-v1/interfaces/IExchange.sol";

import {ISwapRouter} from "./interfaces2/ISwapRouter.sol";
import {IQuoter} from "./interfaces2/IQuoter.sol";

import {FundManagerBaseRelayer} from "./abstract/FundManagerBaseRelayer.sol";

/**
 * @title FundManagerRelayer
 * @notice ERC-2771 compatible version of FundManager.
 * @dev User-facing write functions (withdrawals) use _msgSender() instead of msg.sender
 * to ensure funds are sent to real user, not the relayer.
 */

contract FundManagerRelayer is FundManagerBaseRelayer, IFundManager {
    using SafeERC20 for IERC20;

    // ====================================================================================================================

    error EmptyList();
    error WithdrawError();
    error ApprovalFailed();

    /// @dev Total reward amounts
    mapping(address token => uint256) internal _totalRewardAmounts;

    // Order amounts mapping
    mapping(uint256 boxId => mapping(address buyer => uint256))
        private _orderAmounts;

    // Minter reward amounts
    mapping(address minter => mapping(address token => uint256))
        private _minterRewardAmounts;

    // User reward amounts
    mapping(address helper => mapping(address token => uint256))
        private _helperRewrdAmounts;

    // ====================================================================================================================

    constructor(
        address addrManager_,
        address trustedForwarder_
    ) FundManagerBaseRelayer(addrManager_, trustedForwarder_) {}

    // ====================================================================================================================

    /**
     * @dev Pay order amount (called by project contracts only)
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
     * @dev Pay delay fee (called by project contracts only)
     */
    function payDelayFee(
        uint256 boxId_,
        address sender_,
        uint256 amount_
    ) external onlyProjectContract {
        address officialToken = ADDR_MANAGER.officialToken();
        IERC20(officialToken).transferFrom(sender_, address(this), amount_);

        address minter = TRUTH_BOX.minterOf(boxId_);
        _calculateAllocation(boxId_, minter, amount_, officialToken);

        unchecked {
            _totalRewardAmounts[officialToken] += amount_;
        }
        emit RewardsAdded(boxId_, officialToken, amount_, RewardType.Total);
    }

    // ====================================================================================================================
    // Reward Allocation Functions

    function allocationRewards(uint256 boxId_) external onlyProjectContract {
        address buyer = EXCHANGE.buyerOf(boxId_);
        address minter = TRUTH_BOX.minterOf(boxId_);
        address token = EXCHANGE.acceptedToken(boxId_);

        uint256 amount = _orderAmounts[boxId_][buyer];
        if (amount == 0) revert AmountIsZero();

        _orderAmounts[boxId_][buyer] = 0;
        _calculateAllocation(boxId_, minter, amount, token);

        unchecked {
            _totalRewardAmounts[token] += amount;
        }

        emit RewardsAdded(boxId_, token, amount, RewardType.Total);
    }

    function _calculateAllocation(
        uint256 boxId_,
        address minter_,
        uint256 amount_,
        address token_
    ) private {
        address completer = EXCHANGE.completerOf(boxId_);
        address seller = EXCHANGE.sellerOf(boxId_);
        uint8 sellerRate;
        uint8 completerRate;

        if (completer != address(0)) {
            completerRate = _helperRewardRate;
        }
        if (seller != address(0)) {
            sellerRate = _helperRewardRate;
        }

        uint8 totalRate = _serviceFeeRate + sellerRate + completerRate;

        address officialToken = ADDR_MANAGER.officialToken();

        uint256 amountIn_token;
        uint256 amountOut_official;

        if (token_ != officialToken) {
            totalRate += _extraFeeRate;
            (amountIn_token, amountOut_official) = _swap(
                boxId_,
                token_,
                officialToken,
                amount_,
                totalRate
            );
        } else {
            amountIn_token = (amount_ * totalRate) / 1000;
            amountOut_official = amountIn_token;
        }

        unchecked {
            uint256 sellerRewards = (amountOut_official * sellerRate) /
                totalRate;
            uint256 completerRewards = (amountOut_official * completerRate) /
                totalRate;

            if (completerRewards > 0) {
                _helperRewrdAmounts[completer][
                    officialToken
                ] += completerRewards;
                emit RewardsAdded(
                    boxId_,
                    officialToken,
                    completerRewards,
                    RewardType.Completer
                );
            }
            if (sellerRewards > 0) {
                _helperRewrdAmounts[seller][officialToken] += sellerRewards;
                emit RewardsAdded(
                    boxId_,
                    officialToken,
                    sellerRewards,
                    RewardType.Seller
                );
            }
            _minterRewardAmounts[minter_][token_] += (amount_ - amountIn_token);
            emit RewardsAdded(
                boxId_,
                token_,
                (amount_ - amountIn_token),
                RewardType.Minter
            );

            IERC20(officialToken).safeTransfer(
                ADDR_MANAGER.daoFundManager(),
                (amountOut_official - sellerRewards - completerRewards)
            );
        }
    }

    function _swap(
        uint256 boxId_,
        address tokenIn_,
        address tokenOut_,
        uint256 amount_,
        uint8 totalRate_
    ) private returns (uint256, uint256) {
        address swapContract = SWAP_CONTRACT;
        address quoter = ADDR_MANAGER.quoter();

        if (IERC20(tokenIn_).allowance(address(this), swapContract) < amount_) {
            _approveToken(tokenIn_, swapContract);
        }

        uint256 totalAmountOut = IQuoter(quoter).quoteExactInputSingle(
            tokenIn_,
            tokenOut_,
            3000,
            amount_,
            0
        );

        uint256 amountOut_ = (totalAmountOut * totalRate_) / 1000;

        uint256 amountIn_ = ISwapRouter(swapContract).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenIn_,
                tokenOut: tokenOut_,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountOut: amountOut_,
                amountInMaximum: amount_,
                sqrtPriceLimitX96: 0
            })
        );

        TRUTH_BOX.setPrice(boxId_, totalAmountOut);

        return (amountIn_, amountOut_);
    }

    function _approveToken(address token, address spender) private {
        bool success = IERC20(token).approve(spender, type(uint256).max);
        if (!success) revert ApprovalFailed();
    }

    // ====================================================================================================================
    // Withdrawal Functions

    /**
     * @dev Withdraw order amounts
     * NOTE [ERC-2771]: All msg.sender -> _msgSender() to ensure funds go to real user
     */
    function _withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_,
        FundsType type_
    ) private nonReentrant whenNotPaused {
        if (list_.length == 0) revert EmptyList();
        uint256 amount;
        IExchange exchange = EXCHANGE;
        address sender = _msgSender(); // ERC-2771: extract real sender

        for (uint256 i = 0; i < list_.length; i++) {
            uint256 boxId = list_[i];
            uint256 orderAmount = _orderAmounts[boxId][sender]; // ERC-2771: use real sender
            address buyer = exchange.buyerOf(boxId);
            if (orderAmount == 0) {
                revert AmountIsZero();
            }

            if (type_ == FundsType.Order) {
                if (sender == buyer) revert InvalidCaller(); // ERC-2771: use real sender
            } else if (type_ == FundsType.Refund) {
                if (
                    sender != buyer || // ERC-2771: use real sender
                    !exchange.refundPermit(boxId)
                ) {
                    revert WithdrawError();
                }
                exchange.setRefundPermit(boxId, false);
            }

            if (exchange.acceptedToken(boxId) != token_) {
                revert WithdrawError();
            }
            unchecked {
                amount += orderAmount;
            }
            _orderAmounts[boxId][sender] = 0; // ERC-2771: use real sender
        }

        // Execute transfer to real user, not relayer
        IERC20(token_).safeTransfer(sender, amount); // ERC-2771: transfer to real sender

        uint256 userId = USER_ID.getUserId(sender); // ERC-2771: use real sender
        emit OrderAmountWithdraw(list_, token_, userId, amount, type_);
    }

    function withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_
    ) external {
        _withdrawOrderAmounts(token_, list_, FundsType.Order);
    }

    function withdrawRefundAmounts(
        address token_,
        uint256[] calldata list_
    ) external {
        _withdrawOrderAmounts(token_, list_, FundsType.Refund);
    }

    //--------------------------------------------------

    /**
     * @dev Withdraw helper reward amounts
     * NOTE [ERC-2771]: msg.sender -> _msgSender() to ensure rewards go to real user
     */
    function withdrawHelperRewards(
        address token_
    ) external nonReentrant whenNotPaused {
        address sender = _msgSender(); // ERC-2771: extract real sender

        uint256 amount = _helperRewrdAmounts[sender][token_]; // ERC-2771: use real sender
        if (amount == 0) {
            revert AmountIsZero();
        }
        _helperRewrdAmounts[sender][token_] = 0; // ERC-2771: use real sender
        IERC20(token_).safeTransfer(sender, amount); // ERC-2771: transfer to real sender

        uint256 userId = USER_ID.getUserId(sender); // ERC-2771: use real sender
        emit HelperRewrdsWithdraw(userId, token_, amount);
    }

    /**
     * @dev Withdraw minter rewards
     * NOTE [ERC-2771]: msg.sender -> _msgSender() to ensure rewards go to real user
     */
    function withdrawMinterRewards(
        address token_
    ) external nonReentrant whenNotPaused {
        address sender = _msgSender(); // ERC-2771: extract real sender

        uint256 amount = _minterRewardAmounts[sender][token_]; // ERC-2771: use real sender
        if (amount == 0) {
            revert AmountIsZero();
        }
        _minterRewardAmounts[sender][token_] = 0; // ERC-2771: use real sender
        IERC20(token_).safeTransfer(sender, amount); // ERC-2771: transfer to real sender

        uint256 userId = USER_ID.getUserId(sender); // ERC-2771: use real sender
        emit MinterRewardsWithdraw(userId, token_, amount);
    }

    // ====================================================================================================================
    //                    Query Functions
    // ====================================================================================================================

    function orderAmounts(
        uint256 boxId_,
        address user_
    ) external view onlyProjectContract returns (uint256) {
        return _orderAmounts[boxId_][user_];
    }

    /**
     * @notice SIWE-based _msgSender for read (view) operations.
     */
    function _msgSenderSiwe(
        bytes memory siweToken_
    ) internal view returns (address) {
        address sender = msg.sender;
        if (sender == address(0)) {
            sender = SIWE_AUTH.getMsgSender(siweToken_);
        }
        return sender;
    }

    function orderAmounts(
        uint256 boxId_,
        bytes memory siweToken_
    ) external view onlyProjectContract returns (uint256) {
        address sender = _msgSenderSiwe(siweToken_);
        return _orderAmounts[boxId_][sender];
    }

    function minterRewardAmounts(
        address token_,
        bytes memory siweToken_
    ) external view returns (uint256) {
        address sender = _msgSenderSiwe(siweToken_);
        return _minterRewardAmounts[sender][token_];
    }

    function helperRewardAmounts(
        address token_,
        bytes memory siweToken_
    ) external view returns (uint256) {
        address sender = _msgSenderSiwe(siweToken_);
        return _helperRewrdAmounts[sender][token_];
    }

    // ===================================================================================

    function totalRewardAmounts(address token_) public view returns (uint256) {
        return _totalRewardAmounts[token_];
    }
}
