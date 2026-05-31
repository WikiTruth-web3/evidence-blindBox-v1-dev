// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    error NotAdmin();
    error PeriodNotOver();

    mapping(address => uint256 date) public mintDate;
    uint256 public mintPeriod;
    uint256 public mintAmount;

    address internal ADMIN;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        address deployer = msg.sender == address(0) ? 0x04eB29518D9a94f99B94136884855FFEf239150F : msg.sender;
        ADMIN = deployer;
        mintPeriod = 1 days;
        mintAmount = 1000;
        _mint(deployer, 1000000000 * (10 ** decimals()));
    }

    function mint(address to_) public {
        if (block.timestamp - mintDate[to_] < mintPeriod)
            revert PeriodNotOver();
        _mint(to_, mintAmount * (10 ** decimals()));
        mintDate[to_] = block.timestamp;
    }

    function burn(uint256 amount_) public {
        address from = _msgSender();
        _burn(from, amount_);
    }

    // =====================================
    function setMintPeriod(uint256 period_) public {
        if (msg.sender != ADMIN) revert NotAdmin();
        mintPeriod = period_;
    }

    function setMintAmount(uint256 amount_) public {
        if (msg.sender != ADMIN) revert NotAdmin();
        mintAmount = amount_;
    }
}
