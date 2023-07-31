// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract PToken is ERC20Votes {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) ERC20Permit(name_) {
        _mint(msg.sender, 1_000_000 ether); 
    }
}
