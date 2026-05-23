// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {I_Swap} from "../dex/interfaceSwap.sol";
import {IFundManagerVirtual} from "@interfaces/eth/IFundManagerVirtual.sol";
import {IBuyExecutor} from "@interfaces/eth/IBuyExecutor.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IBuy} from "@interfaces/eth/IBuy.sol";

import {ModifierV2} from "./ModifierV2.sol";

import {PeripheralContracts} from "@interfaces/IContracts.sol";

/**
 *  @notice Peripheral Fund Manager
 *
 */

contract PeripheralFund is ModifierV2{
    IBuy internal BUY;
    I_Swap internal SWAP_CONTRACT;
    IFundManagerVirtual internal FUND_MANAGER_VIRTUAL;

    // ==================================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
    }
    // ==================================================================================================

    // ==========================================================================================================

    function _setPeripheralContracts(PeripheralContracts enum_) internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        if (enum_ != PeripheralContracts.Buy) {
            address contracts = addrMgr.getPeriphContr(PeripheralContracts.Buy);
            if (contracts != address(BUY)) {
                BUY = IBuy(contracts);
            }
        }
        if (enum_ != PeripheralContracts.BuyExecutor) {
            address contracts = addrMgr.getPeriphContr(PeripheralContracts.BuyExecutor);
            if (contracts != address(BUY_EXECUTOR)) {
                BUY_EXECUTOR = IBuyExecutor(contracts);
            }
        }
        if (enum_ != PeripheralContracts.FundManagerVirtual) {
            address contracts = addrMgr.getPeriphContr(PeripheralContracts.FundManagerVirtual);
            if (contracts != address(FUND_MANAGER) ) {
                FUND_MANAGER = IFundManagerVirtual(contracts);
            }
        }
        if (enum_ != PeripheralContracts.SwapContract) {
            address contracts = addrMgr.getPeriphContr(PeripheralContracts.SwapContract);
            if (contracts != address(SWAP_CONTRACT) ) {
                SWAP_CONTRACT = I_Swap(contracts);
            }
        }
    }
}
