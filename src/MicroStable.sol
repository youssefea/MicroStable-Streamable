// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import {SimpleERC20} from "./ERC20.sol";

// contract shUSD is SimpleERC20("Shafu USD", "shUSD", 18, 0) {}

contract MicroStable {
  mapping(address => uint256) public deposit;
  mapping(address => uint256) public minted;

  constructor() {

  }
}
