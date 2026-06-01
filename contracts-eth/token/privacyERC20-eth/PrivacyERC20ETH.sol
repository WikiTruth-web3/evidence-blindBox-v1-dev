// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    IERC20
} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IERC20Errors
} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface PrivacyERC20Errors {
    error ZeroAmount();
    error ZeroAllowances();
    error InsufficientBalance();
}

interface IPrivacyERC20 {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(
        address spender,
        uint256 value
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function wrap(uint256 amount) external;

    function unwrap(uint256 amount) external;

    function getVirtualAddress(address user) external view returns (address);
}

/**
 * @title PrivacyERC20
 * @notice ETH version of Privacy ERC20 Token without encryption and TEE dependencies.
 * Used for testing blind box trading logic in Hardhat environment.
 */
contract PrivacyERC20ETH is
    IERC20Metadata,
    IERC20Errors,
    PrivacyERC20Errors,
    IPrivacyERC20,
    ReentrancyGuard
{
    error EmptyIdentitySalt();
    error ZeroAddress();

    // Master secret for user identity derivation (derived from constructor persistence bytes)
    bytes32 private immutable _identitySalt;

    // State variables mimicking encrypted state in plain text mapping
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Underlying ERC20 token for wrap/unwrap
    IERC20Metadata public immutable underlyingToken;

    constructor(
        address underlyingToken_,
        bytes memory pers_
    ) {
        underlyingToken = IERC20Metadata(underlyingToken_);
        _identitySalt = keccak256(pers_);
    }

    // ERC20 metadata overrides
    function name() public view virtual override returns (string memory) {
        return string(abi.encodePacked("Privacy ", underlyingToken.name(), " with UserId"));
    }

    function symbol() public view virtual override returns (string memory) {
        return string(abi.encodePacked(underlyingToken.symbol(), ".Privacy"));
    }

    function decimals() public view virtual override returns (uint8) {
        return underlyingToken.decimals();
    }

    function totalSupply() public view virtual override returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }

    // Derive mock virtual address securely via hash function
    function _getVirtualAddress(address addr) internal view returns (address) {
        if (addr == address(0)) revert ZeroAddress();
        if (_identitySalt == bytes32(0)) revert EmptyIdentitySalt();

        bytes32 id = keccak256(abi.encodePacked("VirtualAddress", _identitySalt, addr));
        return address(uint160(uint256(id)));
    }

    function _checkContracts(address addr) internal view returns (address) {
        if (addr.code.length > 0) {
            return _getVirtualAddress(addr);
        }
        return addr;
    }

    // Balance query
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (account.code.length > 0 || account == msg.sender) {
            address virtualAddr = _getVirtualAddress(account);
            return _balances[virtualAddr];
        }
        return _balances[account];
    }

    // Allowance query
    function allowance(
        address owner,
        address spender
    ) public view virtual override(IERC20, IPrivacyERC20) returns (uint256) {
        address ownerVirtual = _checkContracts(owner);
        address spenderVirtual = _checkContracts(spender);
        return _allowances[ownerVirtual][spenderVirtual];
    }

    // Standard transfer
    function transfer(address to, uint256 value) public virtual override(IERC20, IPrivacyERC20) returns (bool) {
        address fromVirtual = _getVirtualAddress(msg.sender);
        address toVirtual = _checkContracts(to);
        _transfer(fromVirtual, toVirtual, value);
        return true;
    }

    // Standard approve
    function approve(
        address spender,
        uint256 value
    ) public virtual override(IERC20, IPrivacyERC20) returns (bool) {
        address ownerVirtual = _getVirtualAddress(msg.sender);
        address spenderVirtual = _checkContracts(spender);
        _approve(ownerVirtual, spenderVirtual, value);
        return true;
    }

    // Standard transferFrom
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override(IERC20, IPrivacyERC20) returns (bool) {
        address senderVirtual = _getVirtualAddress(msg.sender);
        address fromVirtual = _checkContracts(from);
        address toVirtual = _checkContracts(to);
        _transferFrom(fromVirtual, toVirtual, senderVirtual, value);
        return true;
    }

    // Internal operations
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        uint256 fromBalance = _balances[from];
        if (fromBalance < value) {
            revert ERC20InsufficientBalance(from, fromBalance, value);
        }

        _balances[from] = fromBalance - value;
        _balances[to] = _balances[to] + value;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _checkSpendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }

    function _transferFrom(
        address from,
        address to,
        address sender,
        uint256 value
    ) internal {
        _checkSpendAllowance(from, sender, value);
        _transfer(from, to, value);
    }

    function getMyVirtualAddress() external view returns (address) {
        return _getVirtualAddress(msg.sender);
    }

    // Wrap & Unwrap implementation (acting as 1:1 backed private wrapper)
    function wrap(uint256 amount) external override nonReentrant {
        if (amount == 0) revert ZeroAmount();

        underlyingToken.transferFrom(msg.sender, address(this), amount);

        address senderVirtual = _getVirtualAddress(msg.sender);
        uint256 currentBalance = _balances[senderVirtual];
        _balances[senderVirtual] = currentBalance + amount;
    }

    function unwrap(uint256 amount) external override nonReentrant {
        if (amount == 0) revert ZeroAmount();

        address senderVirtual = _getVirtualAddress(msg.sender);
        uint256 currentBalance = _balances[senderVirtual];
        if (currentBalance < amount) revert InsufficientBalance();

        _balances[senderVirtual] = currentBalance - amount;
        underlyingToken.transfer(msg.sender, amount);
    }

    // Get virtual address of a user only if spender is authorized (has non-zero allowance)
    function getVirtualAddress(address user) external view override returns (address) {
        address userVirtual = _getVirtualAddress(user);
        address spenderVirtual = _getVirtualAddress(msg.sender);

        if (_allowances[userVirtual][spenderVirtual] == 0) revert ZeroAllowances();

        return userVirtual;
    }
}
