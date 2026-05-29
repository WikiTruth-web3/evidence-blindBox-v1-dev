// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

interface FundManagerEvents {

    event OrderAmountPaid(
        uint256 indexed boxId,
        bytes32 indexed userId,
        address indexed token,
        uint256 amount
    );

    event OrderAmountWithdraw(
        uint256[] list,
        address indexed token,
        bytes32 indexed userId,
        uint256 amount
    );

    event RefundAmountWithdraw(
        uint256[] list,
        address indexed token,
        bytes32 indexed userId,
        uint256 amount
    );

    event RewardsAdded(
        uint256 indexed boxId,
        address indexed token,
        uint256 amount,
        RewardsType rewardsType
    );

    event RewardsWithdraw(
        bytes32 indexed userId,
        address indexed token,
        uint256 amount
    );
}

enum FundsType {
    Order,
    Refund
}

enum RewardsType {
    Minter,
    Seller,
    Completer
}

/**
 * @title IFundManager
 * @notice FundManager contract interface, defining all externally exposed functions and events
 * @dev This interface serves as the top-level constraint for the FundManager contract, ensuring consistency between interface and implementation
 */
interface IFundManager {
    // =====================================================================================
    //                                          Address Management
    // =====================================================================================

    /**
     * @notice Set contract addresses
     * @dev Get and set related contract addresses from AddressManager
     */
    function setContracts() external;

    // =====================================================================================
    //                                          Payment Functions (Project Contracts Only)
    // =====================================================================================

    /**
     * @notice Pay order amount
     * @param boxId_ BlindBox ID
     * @param buyer_ Buyer address
     * @param amount_ Amount to pay
     * @param userId_ Buyer id
     * @dev Only callable by project contracts
     */
    function payOrderAmount(
        uint256 boxId_,
        address buyer_,
        uint256 amount_,
        bytes32 userId_
    ) external;

    /**
     * @notice Pay delay fee
     * @param boxId_ BlindBox ID
     * @param buyer_ Buyer address
     * @param amount_ Amount to pay
     * @dev Only callable by project contracts
     */
    function payDelayFee(
        uint256 boxId_,
        address buyer_,
        uint256 amount_
    ) external;

    /**
     * @notice Allocate rewards
     * @param boxId_ BlindBox ID
     * @dev Only callable by project contracts
     */
    function allocationRewards(uint256 boxId_) external;

    // =====================================================================================
    //                                          Withdrawal Functions
    // =====================================================================================

    /**
     * @notice Withdraw order amounts (for buyers who failed to participate in bidding)
     * @param token_ Token address
     * @param list_ List of BlindBox IDs
     * @param virtual_ user virtual address(privacy erc20)
     */
    function withdrawOrderAmounts(
        address token_,
        uint256[] calldata list_,
        address virtual_
    ) external;

    /**
     * @notice Withdraw refund amounts
     * @param token_ Token address
     * @param list_ List of BlindBox IDs
     * @param virtual_ user virtual address(privacy erc20)
     */
    function withdrawRefundAmounts(
        address token_,
        uint256[] calldata list_,
        address virtual_
    ) external;

    /**
     * @notice Withdraw rewards
     * @param token_ Token address
     * @param virtual_ user virtual address(privacy erc20)
     */
    function withdrawRewards(address token_, address virtual_) external;

    // =====================================================================================
    //                                          Getter Functions
    // =====================================================================================

    /**
     * @dev Get order amount
     * @param boxId_ BlindBox ID
     * @param userId_ User ID
     * @return Order amount
     */
    function orderAmounts(
        uint256 boxId_,
        bytes32 userId_
    ) external view returns (uint256);

    /**
     * @notice Get reward amount
     * @param userId_ User Id
     * @param token_ Token address
     * @return reward amount
     */
    function rewardAmounts(
        bytes32 userId_,
        address token_
    ) external view returns (uint256);

    /**
     * @notice Get total reward amount
     * @param token_ Token address
     * @return Total reward amount
     */
    // function totalRewardAmounts(address token_) external view returns (uint256);
}
