// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.20;

import {
    ERC2771Forwarder
} from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

import {IForwarder} from "@interfaces/IForwarder.sol";
import {Main} from "@interfaces/base/IContracts.sol";

import {Pausable} from "./abstract/Pausable.sol";

import {Forwarder01} from "./base/Forwarder01.sol";
/**
 * @title Forwarder
 * @dev Has enhanced control functions ERC-2771 forwarder.
 * Includes: relayer whitelist, target contract whitelist, gas limit and emergency pause function.
 * This contract is specifically used to handle meta-transactions, using EIP-712 signatures.
 */
contract Forwarder is IForwarder, ERC2771Forwarder, Forwarder01, Pausable {
    error NotWhitelistedTarget();
    error GasLimitExceeded();

    // ========================


    // =====================================================================================

    constructor(
        string memory name,
        address addrManager_
    ) ERC2771Forwarder(name) Forwarder01(addrManager_) {}

    // =====================================================================================

    /**
     * @notice Initialize contract references
     */
    function setContracts() external onlyAdmin {
        _setContracts();
    }


    // =====================================================================================
    //                                  Management Functions
    // =====================================================================================

    function pause() external onlyAdminDAO {
        _pause();
    }

    function unpause() external onlyAdminDAO {
        _unpause();
    }

    // =====================================================================================
    //                                     Overrides
    // =====================================================================================

    function execute(
        ForwardRequestData calldata request
    ) public payable override whenNotPaused onlyValidRelayer {
        _preExecuteCheck(request);
        super.execute(request);
    }

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

    function _preExecuteCheck(
        ForwardRequestData calldata request
    ) internal view {
        // 1. Check if the target contract is in the whitelist
        if (!_targetWhitelist[request.to]) revert NotWhitelistedTarget();

        // 2. Check gas limit (if limit is set)
        if (_maxGasLimit > 0 && request.gas > _maxGasLimit)
            revert GasLimitExceeded();
    }


}
