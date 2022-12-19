// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XToken is ERC20{
    constructor() ERC20("xVote", "XVT"){
  _mint(msg.sender,2000*10**18);
    }
}