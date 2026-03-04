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

pragma solidity ^0.8.20;

import {
    ERC2771Forwarder
} from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

import {IAddressManager} from "@marketplace-v1/interfaces/IAddressManager.sol";
import {IUserManager} from "@marketplace-v1/interfaces/IUserManager.sol";
import {IForwarder} from "@marketplace-v1/interfaces/IForwarder.sol";
import {Modifier} from "./modifier/Modifier.sol";

import {Pausable} from "./utils/Pausable.sol";

/**
 * @title Forwarder
 * @dev Has enhanced control functions ERC-2771 forwarder.
 * Includes: relayer whitelist, target contract whitelist, gas limit and emergency pause function.
 * This contract is specifically used to handle meta-transactions, using EIP-712 signatures.
 */
contract Forwarder is ERC2771Forwarder, Modifier, IForwarder, Pausable {
    error RelayerIsBlacklisted();
    error NotWhitelistedTarget();
    error GasLimitExceeded();
    error ContractPaused();

    // ========================

    IUserManager internal USER_MANAGER;

    mapping(address => bool) internal _targetWhitelist;

    uint256 internal _maxGasLimit;

    // =====================================================================================

    constructor(
        string memory name,
        address addrManager_
    ) ERC2771Forwarder(name) Modifier(addrManager_) {}

    // =====================================================================================
    //                                  System Configuration
    // =====================================================================================

    /**
     * @notice Initialize contract references
     */
    function setAddress() external onlyManager {
        address userMgr = ADDR_MANAGER.userManager();
        if (userMgr != address(0)) {
            USER_MANAGER = IUserManager(userMgr);
        }
    }

    // =====================================================================================
    //                                     Modifiers
    // =====================================================================================

    /**
     * @dev Check relayer identity:
     * 1. Must be in the whitelist
     * 2. If associated with UserManager, cannot be in the blacklist
     */
    modifier onlyValidRelayer() {
        if (
            address(USER_MANAGER) != address(0) &&
            USER_MANAGER.isBlacklisted(msg.sender)
        ) {
            revert RelayerIsBlacklisted();
        }
        _;
    }

    // =====================================================================================
    //                                  Management Functions
    // =====================================================================================

    /**
     * @notice Set target contract whitelist status
     */
    function setTargetStatus(address target_, bool status_) external onlyAdmin {
        _targetWhitelist[target_] = status_;
    }

    /**
     * @notice Set gas limit per transaction
     */
    function setMaxGasLimit(uint256 maxGasLimit_) external onlyAdmin {
        _maxGasLimit = maxGasLimit_;
    }

    /**
     * @notice pause status
     */
    function pause() external onlyAdminDAO {
        _pause();
    }

    /**
     * @notice unpause status
     */
    function unpause() external onlyAdminDAO {
        _unpause();
    }

    // =====================================================================================
    //                                     Overrides
    // =====================================================================================

    /**
     * @dev Override single execution function to add custom checks
     */
    function execute(
        ForwardRequestData calldata request
    ) public payable override whenNotPaused onlyValidRelayer {
        _preExecuteCheck(request);
        super.execute(request);
    }

    /**
     * @dev Override batch execution function to add custom checks
     */
    function executeBatch(
        ForwardRequestData[] calldata requests,
        address payable refundReceiver
    ) public payable override whenNotPaused onlyValidRelayer {
        for (uint256 i = 0; i < requests.length; i++) {
            _preExecuteCheck(requests[i]);
        }
        super.executeBatch(requests, refundReceiver);
    }

    // =====================================================================================
    //                                  Internal Helpers
    // =====================================================================================

    /**
     * @dev Core pre-execution check logic
     * @param request Request data
     */
    function _preExecuteCheck(
        ForwardRequestData calldata request
    ) internal view {
        // 1. Check if the target contract is in the whitelist
        if (!_targetWhitelist[request.to]) revert NotWhitelistedTarget();

        // 2. Check gas limit (if limit is set)
        if (_maxGasLimit > 0 && request.gas > _maxGasLimit)
            revert GasLimitExceeded();
    }

    // =====================================================================================
    //                                     Getters
    // =====================================================================================

    function isTargetWhitelisted(address target_) external view returns (bool) {
        return _targetWhitelist[target_];
    }

    function getMaxGasLimit() external view returns (uint256) {
        return _maxGasLimit;
    }
}
