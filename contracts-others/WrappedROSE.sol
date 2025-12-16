// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title WrappedROSE
 * @dev WrappedROSE is a ERC20 token that is wrapped around the ROSE token
 * This is Oasis(https://docs.oasis.dev/) Sapphire's wrapped ROSE token
 * sapphire testnet: https://explorer.sapphire.oasis.dev/address/0x493545123261915b6d404151b290548643473749
 * sapphire mainnet: https://explorer.sapphire.oasis.dev/address/0x274802465b594882901541293217a89292629889
 */

contract WrappedROSE is ERC20, ERC20Burnable {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    //solhint-disable-next-line no-empty-blocks
    constructor() ERC20("Wrapped ROSE", "wROSE") {}

    function deposit() external payable {
        _deposit();
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    receive() external payable {
        _deposit();
    }

    function _deposit() internal {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }
}
