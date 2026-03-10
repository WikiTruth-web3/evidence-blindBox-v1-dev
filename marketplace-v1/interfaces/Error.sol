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

/**
 * @title Error Interface
 * @dev Defines standard error types used across the protocol
 */
interface Error {
    // =====================================================================================
    // Permission and Administration Errors
    // =====================================================================================

    /// @dev Thrown when a function is called by a non-admin account
    error NotAdmin();

    /// @dev Thrown when a function requires admin or DAO permissions
    error NotAdminOrDAO();

    /// @dev Thrown when an account is not the minter of a token
    error NotMinter();

    /// @dev Thrown when caller is not the buyer of a token
    error NotBuyer();

    /// @dev Thrown when an account is not the DAO
    error NotDAO();

    // error NotOwner();  // Commented out but kept for reference

    // =====================================================================================
    // Contract Interaction Errors
    // =====================================================================================

    /// @dev Thrown when a zero address is provided where a valid address is required
    error ZeroAddress();

    /// @dev Thrown when implementation address is invalid
    error InvalidImplementation();

    /// @dev Thrown when caller is not authorized to call a function
    error InvalidCaller();

    /// @dev Thrown when a deadline is invalid
    error InvalidDeadline();

    /// @dev Thrown when a project contract caller is not authorized
    error NotProjectCaller();

    /// @dev Thrown when seconds is invalid
    error InvalidSeconds();

    // =====================================================================================
    // State and Validation Errors
    // =====================================================================================

    /// @dev Thrown when operation is performed in an invalid status
    error InvalidStatus();

    /// @dev Thrown when a token is in blacklist
    error InBlacklist();

    /// @dev
    error NotInBlacklist();

    /// @dev Thrown when a box does not exist
    error BoxNotExists();

    /// @dev Thrown when token is not in secrecy state
    error NotInSecrecy();

    // =====================================================================================
    // Parameter and Data Errors
    // =====================================================================================

    /// @dev Thrown when provided rate is invalid
    error InvalidRate();

    /// @dev Thrown when token info is empty or not properly provided during token creation or update
    error EmptyTokenCID();

    /// @dev Thrown when price is empty or zero
    error EmptyPrice();

    /// @dev Thrown when box info CID is empty
    error EmptyBoxInfoCID();

    /// @dev Thrown when list is empty
    error EmptyList();

    /// @dev Thrown when key is empty
    error EmptyKey();

    /// @dev Thrown when user id is empty
    error EmptyUserId();

    /// @dev Thrown when withdraw failed
    error WithdrawError();

    /// @dev Thrown when approval failed
    error ApprovalFailed();

    // =====================================================================================
    // Transaction and Business Logic Errors
    // =====================================================================================

    /// @dev Thrown when auction is already over
    error AuctionOver();

    /// @dev Thrown when deadline is not over yet
    error DeadlineNotOver();

    /// @dev Thrown when not in window period
    error NotInWindowPeriod();

    /// @dev Thrown when deadline is already over
    error DeadlineIsOver();

    /// @dev Thrown when buyer is available for a token
    error AvailableBuyer();

    /// @dev Thrown when public time is not ended
    error PublicTimeNotEnd();

    /// @dev Thrown when period parameter is invalid
    error InvalidPeriod();

    // =====================================================================================
    // v1.8 Errors
    // =====================================================================================

    /// @dev Thrown when an invalid or incompatible contract address is provided
    error InvalidContractAddress();

    /// @dev Thrown when attempting to register a token that already exists in the system
    error TokenAlreadyExists();

    /// @dev Thrown when a contract does not implement the required ERC20 interface
    error InvalidERC20Interface();

    /// @dev Thrown when attempting to interact with a token that doesn't exist in the registry
    error TokenNotExists();

    /// @dev Thrown when an amount parameter is zero or empty
    error AmountIsZero();

    /// @dev Thrown when attempting to use a token that is not supported by the protocol
    error TokenNotSupported();

    /// @dev Thrown when refund permit is true
    error RefundPermitTrue();
}
