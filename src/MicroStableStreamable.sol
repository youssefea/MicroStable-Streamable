// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import { CustomSuperTokenBase } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
import { UUPSProxy } from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";
import { ISuperToken, ISuperTokenFactory, IERC20 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";


interface Oracle { function latestAnswer() external view returns (uint); }

contract ShUSD is ERC20("Shafu USD", "shUSD", 18), CustomSuperTokenBase, UUPSProxy {
  address public manager;

  constructor(address _manager) { 
    require(ERC20(address(this)).decimals() == 18, "Decimals must be 18");
    manager = _manager; }

  modifier onlyManager() {
    require(manager == msg.sender);
    _;
  }

  function mint(address to,   uint amount) public onlyManager { _mint(to,   amount); }
  function burn(address from, uint amount) public onlyManager { _burn(from, amount); }

  function initialize(
		ISuperTokenFactory factory
	) external {
		// This call to the factory invokes `UUPSProxy.initialize`, which connects the proxy to the canonical SuperToken implementation.
		// It also emits an event which facilitates discovery of this token.
		ISuperTokenFactory(factory).initializeCustomSuperToken(address(this));

		// This initializes the token storage and sets the `initialized` flag of OpenZeppelin Initializable.
		// This makes sure that it will revert if invoked more than once.
		ISuperToken(address(this)).initialize(
			IERC20(address(0)),
			18,
			ERC20(address(this)).name(),
			ERC20(address(this)).symbol()
		);
	}

}

contract Manager {
  uint public constant MIN_COLLAT_RATIO = 1.5e18;

  ERC20 public weth;
  ShUSD public shUSD;

  Oracle public oracle;

  mapping(address => uint) public address2deposit;
  mapping(address => uint) public address2minted;

  constructor(address _weth, address payable _shUSD, address _oracle) {
    weth   = ERC20(_weth);
    shUSD  = ShUSD(_shUSD);
    oracle = Oracle(_oracle);
  }

  function deposit(uint amount) public {
    weth.transferFrom(msg.sender, address(this), amount);
    address2deposit[msg.sender] += amount;
  }

  function burn(uint amount) public {
    address2minted[msg.sender] -= amount;
    shUSD.burn(msg.sender, amount);
  }

  function mint(uint amount) public {
    address2minted[msg.sender] += amount;
    require(collatRatio(msg.sender) >= MIN_COLLAT_RATIO);
    shUSD.mint(msg.sender, amount);
  }

  function withdraw(uint amount) public {
    address2deposit[msg.sender] -= amount;
    require(collatRatio(msg.sender) >= MIN_COLLAT_RATIO);
    weth.transfer(msg.sender, amount);
  }

  function liquidate(address user) public {
    require(collatRatio(user) < MIN_COLLAT_RATIO);
    shUSD.burn(msg.sender, address2minted[user]);
    weth.transfer(msg.sender, address2deposit[user]);
    address2deposit[user] = 0;
    address2minted[user] = 0;
  }

  function collatRatio(address user) public view returns (uint) {
    uint minted = address2minted[user];
    if (minted == 0) return type(uint256).max;
    uint totalValue = address2deposit[user] * oracle.latestAnswer() / 1e18;
    return totalValue / minted;
  }
}
