// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {PrivacyERC20} from "../PrivacyERC20.sol";

/**
 * @title TransferFromTest
 * @notice A simple test contract to verify depositing funds using the PrivacyERC20's transferFrom function.
 */
contract TransferFromTest {
    PrivacyERC20 public immutable privacyToken;

    // Track the deposited balances of users (using their real EOA addresses)
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, address indexed virtualAddress, uint256 amount);

    constructor(address privacyToken_) {
        privacyToken = PrivacyERC20(privacyToken_);
    }

    /**
     * @notice Deposits funds into this contract using transferFrom.
     * @dev The user must have approved this contract first by calling approve(spender, amount) on the PrivacyERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(uint256 amount) external {
        // Retrieve the virtual address of msg.sender.
        // This call will only succeed if the user has approved this contract (allowance > 0).
        address virtualAddr = privacyToken.getVirtualAddress(msg.sender);

        // Perform transferFrom. 
        // We pass the user's virtual address as `from` because the allowance check in the privacy ERC20 
        // is performed between the virtual address of the owner and the virtual address of the spender.
        // `address(this)` is the contract itself, which will automatically resolve to its virtual address.
        bool success = privacyToken.transferFrom(virtualAddr, address(this), amount);
        require(success, "TransferFrom failed");

        // Update the contract's local state tracking
        balances[msg.sender] += amount;

        emit Deposit(msg.sender, virtualAddr, amount);
    }
}
