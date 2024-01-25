// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20{
    address payable owner;
    

    constructor() ERC20("USDT", "USDT") {

        // ICO =address(new ico(msg.sender,this));
         owner=payable(msg.sender);
        _mint(owner, 1000);
       
    }
}