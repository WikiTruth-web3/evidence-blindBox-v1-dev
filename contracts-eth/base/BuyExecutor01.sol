// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {IFundManagerVirtual} from "@interfaces/eth/IFundManagerVirtual.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IExchange} from "@interfaces/eth/IExchange.sol";

import {ModifierV3} from "../modifier/ModifierV3.sol";

import {PeripheralContracts, CoreContracts} from "@interfaces/IContracts.sol";

/**
 *  @notice Peripheral Fund Manager
 *
 */

contract BuyExecutorSet is ModifierV3{
    address public executor;

    IExchange internal EXCHANGE;
    IFundManagerVirtual internal FUND_MANAGER_VIRTUAL;

    // ==================================================================================================
    constructor(address addrManager_, address executor_) ModifierV3(addrManager_) {
        executor = executor_;

    }

    modifier onlyExecutor() {
        if (msg.sender != executor) revert InvalidCaller();
        _;
    }

    // ==================================================================================================

    function setExecutor(address executor_) external onlyAdmin {
        if(executor == address(0)) revert ZeroAddress();
        executor = executor_;
    }

    function _setContracts() internal onlyManager {
        IAddressManager addrMgr = ADDR_MANAGER;
        address contracts = addrMgr.getCoreContract(CoreContracts.Exchange);
        if (contracts != address(EXCHANGE )) {
            EXCHANGE = IExchange(contracts);
        }
        address contracts = addrMgr.getPeriphContr(PeripheralContracts.FundManagerVirtual);
        if (contracts != FUND_MANAGER_VIRTUAL ) {
            FUND_MANAGER_VIRTUAL = contracts;
        }

    }
}
