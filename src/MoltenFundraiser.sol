// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MoltenFundraiser is ERC20 {
    uint256 public lockingDuration;
    uint256 public exchangeTime;
    ERC20 public daoToken;

    IERC20 public depositToken;
    // ⚠️  This mapping is not emptied on exchange. After exchange, its values
    // are really only what was deposited by a given address.
    mapping(address => uint256) public deposited;
    // ⚠️  Not emptied on exchange.
    uint256 public totalDeposited;
    address public daoTreasuryAddress;

    uint256 public exchangeRate;

    constructor(
        address daoTokenAddress,
        uint256 _lockingDuration,
        address depositTokenAddress,
        address _daoTreasuryAddress
    )
        public
        ERC20("Molten token", "mToken") // ERC20(
    //     string.concat("Molten ", daoToken.name()),
    //     string.concat("m", daoToken.symbol())
    // )
    {
        lockingDuration = _lockingDuration;
        daoToken = ERC20(daoTokenAddress);
        depositToken = IERC20(depositTokenAddress);
        daoTreasuryAddress = _daoTreasuryAddress;
    }

    function deposit(uint256 amount) public {
        require(exchangeTime == 0, "Molten: exchange happened");
        deposited[msg.sender] += amount;
        totalDeposited += amount;
        depositToken.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @param _exchangeRate is the number of deposit wei-tokens valued the same as 1
     * DAO token.
     */
    function exchange(uint256 _exchangeRate) public {
        require(exchangeTime == 0, "Molten: exchange happened");
        exchangeTime = block.timestamp;

        exchangeRate = _exchangeRate;
        uint256 daoTokenTotal = totalDeposited / exchangeRate;

        _mint(address(this), daoTokenTotal);
        depositToken.transfer(daoTreasuryAddress, totalDeposited);
        daoToken.transferFrom(msg.sender, address(this), daoTokenTotal);
    }

    function claimMTokens() public {
        require(exchangeTime > 0, "Molten: exchange not happened");

        // [FIXME] We are not making sure that the total amount of claimable
        // mTokens is going to match exactly the total minted supply.
        _transfer(
            address(this),
            msg.sender,
            deposited[msg.sender] / exchangeRate
        );
    }

    // function redeem() public {
    //     require(
    //         block.timestamp >= exchangeTime + lockingDuration,
    //         "Molten: still locked"
    //     );
    // }
}
