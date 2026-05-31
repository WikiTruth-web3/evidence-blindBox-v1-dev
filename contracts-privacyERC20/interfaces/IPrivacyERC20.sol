// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;

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
    
    /**
     *  @dev Get the virtual address of a user
     * @param user The user address(real)
     * @return The virtual address of the user
     * In contract the user is msg.sender
     * You can use that function In your smart contract to get the virtual address of a user
     */
    function getVirtualAddress(address user) external view returns (address);

}
