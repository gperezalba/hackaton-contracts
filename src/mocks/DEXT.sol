// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";

contract DEXT is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("DEXT", "DEXT") ERC20Permit("DEXT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
