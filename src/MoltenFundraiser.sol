// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract MoltenFundraiser {
    uint256 public lockingDuration;
    uint256 public exchangeTime;
    IERC20 public daoToken;

    IERC20 public depositToken;
    uint256 public totalDeposits;
    mapping(address => uint256) public deposits;

    constructor(
        address daoTokenAddress,
        uint256 _lockingDuration,
        address depositTokenAddress
    ) public {
        lockingDuration = _lockingDuration;
        daoToken = IERC20(daoTokenAddress);
        depositToken = IERC20(depositTokenAddress);
    }

    function deposit(uint256 amount) public {
        deposits[msg.sender] += amount;
        totalDeposits += amount;
        depositToken.transferFrom(msg.sender, address(this), amount);
    }

    function exchange(uint256 amount) public {
        daoToken.transferFrom(msg.sender, address(this), amount);
    }
}
