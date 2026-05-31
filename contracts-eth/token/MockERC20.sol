// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    error NotAdmin();

    // mapping(address => uint256 date) public mintDate;
    uint8 internal _decimals;
    address internal ADMIN;

    // name: Test WETH for WikiTruth
    // symbol: TWETH
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        ADMIN = msg.sender;
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to_) public {
        // if(msg.sender != ADMIN) revert NotAdmin();
        _mint(to_, 100000000000 * (10 ** uint256(_decimals)));
    }

    function burn(uint256 amount_) public {
        address from = _msgSender();
        _burn(from, amount_);
    }
}
