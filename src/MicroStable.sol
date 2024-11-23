// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract ShUSD is ERC20("Shafu USD", "shUSD", 18) {
  address public manager;

  constructor(address _manager) { manager = _manager; }

  modifier onlyManager() {
    require(manager == msg.sender);
    _;
  }

  function mint(address to,   uint amount) public onlyManager { _mint(to,   amount); }
  function burn(address from, uint amount) public onlyManager { _burn(from, amount); }
}

contract Manager {
  ERC20 public weth;
  ShUSD public shUSD;

  mapping(address => uint) public deposit;
  mapping(address => uint) public minted;

  constructor(address _weth, address _shUSD) {
    weth  = ERC20(_weth);
    shUSD = ShUSD(_shUSD);
  }
}
