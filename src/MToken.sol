// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20, ERC20Pausable, Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// [XXX] Hijack balanceOf thanks to deposits in the funding contract

contract MToken is ERC20Pausable, Ownable {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        Pausable()
        Ownable()
    {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }
}
