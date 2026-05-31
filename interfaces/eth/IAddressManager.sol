// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

import {Main} from "@interfaces/IContracts.sol";


interface AddressManagerEvents {
    event CoreContractAdded(address indexed _contract);
    event CoreContractRemoved(address indexed _contract);
    event AddressSet(bytes32 indexed _key, address indexed _value);
    event AddressRemoved(bytes32 indexed _key);
}

/**
 * @title IAddressManager
 * @notice AddressManager contract interface, defining all externally exposed functions
 * @dev This interface serves as the top-level constraint for the AddressManager contract, ensuring consistency between interface and implementation
 */
interface IAddressManager {
    // =====================================================================================
    //                                          Address Getters
    // =====================================================================================

    /**
     * @notice Get core contract address
     * @param name_ Core contract name
     * @return Core contract address
     */
    function getMainContract(Main name_) external view returns (address);

    /**
     * @notice Get contract address
     * @param _name Contract name
     * @return Contract address
     */
    function getSpreadContract(string memory _name) external view returns (address);

    // =====================================================================================
    //                                          Address Management Functions (Admin Only)
    // =====================================================================================

    /**
     * @notice set all contract addresses
     * @dev Only callable by admin, calls setAddress() on all project contracts
     */
    // function setAllContracts() external;

    // =====================================================================================
    //                                          Token Management Functions (Admin Only)
    // =====================================================================================

    /**
     * @notice Set settlement token
     * @param token_ Settlement token address
     * @dev Only callable by admin
     */
    function setSettlementToken(address token_) external;

    /**
     * @notice Add token to supported list
     * @param token_ Token address to add
     * @dev Only callable by admin
     */
    function addToken(address token_) external;

    /**
     * @notice Remove token from supported list
     * @param token_ Token address to remove
     * @dev Only callable by admin, sets token status to Inactive
     */
    function removeToken(address token_) external;

    // =====================================================================================
    //                                          Getter Functions
    // =====================================================================================

    /**
     * @notice Check if address is a project contract
     * @param contract_ Contract address to check
     * @return Whether the address is a project contract
     */
    function isProjectContract(address contract_) external view returns (bool);

    /**
     * @notice Get settlement token address
     * @return Settlement token address
     */
    function settlementToken() external view returns (address);


    // function checkTokenSupported(address token_) external view ;

    /**
     * @notice Check if token is supported
     * @param token_ Token address to check
     * @return Whether the token is supported (Active status)
     */
    function isTokenSupported(address token_) external view returns (bool);

    /**
     * @notice Check if token is settlement token
     * @param token_ Token address to check
     * @return Whether the token is the settlement token
     */
    function isSettlementToken(address token_) external view returns (bool);

    /**
     * @notice Get token list
     * @return Array of all token addresses
     */
    function getTokenList() external view returns (address[] memory);

}
