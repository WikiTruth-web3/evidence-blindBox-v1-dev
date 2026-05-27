// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {I_Swap} from "../dex/interfaceSwap.sol";
import {IAddressManager} from "@interfaces/eth/IAddressManager.sol";
import {IBuy} from "@interfaces/eth/IBuy.sol";

import {ModifierV2} from "./ModifierV2.sol";

import {PeripheralContracts} from "@interfaces/IContracts.sol";

/**
 *  @notice Peripheral Fund Manager
 *
 */

contract PeripheralFund is ModifierV2{

    I_Swap internal SWAP_CONTRACT;

    // ==================================================================================================
    constructor(address addrManager_) ModifierV2(addrManager_) {
    }
    // ==================================================================================================

    // ==========================================================================================================

    function _setPeripheralContracts(PeripheralContracts enum_) internal virtual {
        IAddressManager addrMgr = ADDR_MANAGER;

        if (enum_ != PeripheralContracts.SwapContract) {
            address contracts = addrMgr.getPeriphContr(PeripheralContracts.SwapContract);
            if (contracts != address(SWAP_CONTRACT) ) {
                SWAP_CONTRACT = I_Swap(contracts);
            }
        }
    }
}
