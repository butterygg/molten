// SPDX-License-Identifier: UNLICENSED
// solhint-disable not-rely-on-time
pragma solidity ^0.8.13;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable, Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Votes, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// [TODO] Split: ERC20
// [TODO] Split: RefundEscrow
// [TODO] Check attack vectors and add counter measures (reentrancy mutex…)
// [TODO] Add best practices (events…)

contract MoltenFunding is ERC20Pausable {
    address public candidateAddress;

    uint256 public lockingDuration;
    uint256 public exchangeTime;
    ERC20Votes public daoToken;

    IERC20 public depositToken;
    // ⚠️  This mapping is not emptied on exchange. After exchange, its values
    // are really only what was deposited by a given address.
    mapping(address => uint256) public deposited;
    // ⚠️  Not emptied on exchange.
    uint256 public totalDeposited;
    address public daoTreasuryAddress;

    uint256 public exchangeRate;

    uint256 public liquidationTime;
    mapping(address => bool) public votedForLiquidation;
    uint256 public totalVotesForLiquidation;

    constructor(
        address daoTokenAddress,
        uint256 _lockingDuration,
        address depositTokenAddress,
        address _daoTreasuryAddress
    )
        ERC20("Molten token", "mToken") // ERC20(
        //     string.concat("Molten ", daoToken.name()),
        //     string.concat("m", daoToken.symbol())
        // )
        Pausable()
    {
        candidateAddress = msg.sender;
        lockingDuration = _lockingDuration;
        daoToken = ERC20Votes(daoTokenAddress);
        depositToken = IERC20(depositTokenAddress);
        daoTreasuryAddress = _daoTreasuryAddress;
    }

    function deposit(uint256 amount) external {
        require(exchangeTime == 0, "Molten: exchange happened");

        deposited[msg.sender] += amount;
        totalDeposited += amount;
        depositToken.transferFrom(msg.sender, address(this), amount);
    }

    function refund(uint256 amount) external {
        require(exchangeTime == 0, "Molten: exchange happened");
        require(
            amount <= deposited[msg.sender],
            "Molten: refund amount too large"
        );

        deposited[msg.sender] -= amount;
        totalDeposited += amount;
        depositToken.transfer(msg.sender, amount);
    }

    /**
     * @notice Delegates to candidate and swaps dao tokens for deposit tokens.
     * ⚠️  Nothing resets delegation in this contract.
     * @param _exchangeRate is the number of deposit wei-tokens valued the same as 1`
     * DAO token.
     */
    function exchange(uint256 _exchangeRate) external {
        require(
            msg.sender == daoTreasuryAddress,
            "Molten: exchange only by DAO"
        );
        require(exchangeTime == 0, "Molten: exchange happened");

        daoToken.delegate(candidateAddress);
        exchangeTime = block.timestamp;
        exchangeRate = _exchangeRate;

        uint256 daoTokenTotal = totalDeposited / exchangeRate;

        _mint(address(this), daoTokenTotal);

        depositToken.transfer(daoTreasuryAddress, totalDeposited);
        daoToken.transferFrom(msg.sender, address(this), daoTokenTotal);
    }

    function _daoTokensBalance(address account) private view returns (uint256) {
        assert(exchangeRate > 0);

        return deposited[account] / exchangeRate;
    }

    function claimMTokens() external {
        require(deposited[msg.sender] > 0, "Molten: no mToken to claim");
        require(exchangeTime > 0, "Molten: exchange not happened");

        // [FIXME] We are not making sure that the total amount of claimable
        // mTokens is going to match exactly the total minted supply.
        _transfer(address(this), msg.sender, _daoTokensBalance(msg.sender));
    }

    /**
     * @notice Sets the contract as liquidated, which allows claiming of DAO
     * governance tokens by mToken holders.
     * ⚠️  Does not reset delegation. After claiming their tokens, token holders
     * need to change their delegation.
     */
    function liquidate() external {
        require(exchangeTime > 0, "Molten: exchange not happened");

        bool lockEnded = block.timestamp >= exchangeTime + lockingDuration;
        bool unanimousLiquidationVote = totalVotesForLiquidation ==
            totalDeposited;

        require(lockEnded || unanimousLiquidationVote, "Molten: locked");

        daoToken.delegate(address(0x00));
        liquidationTime = block.timestamp;

        _pause();
    }

    function claim() external {
        require(deposited[msg.sender] > 0, "Molten: nothing to claim");
        require(liquidationTime > 0, "Molten: not liquidated");

        _unpause();
        _burn(msg.sender, balanceOf(msg.sender));
        _pause();

        daoToken.transfer(msg.sender, _daoTokensBalance(msg.sender));
    }

    function voteForLiquidation() external {
        require(deposited[msg.sender] > 0, "Molten: no voting power");
        require(exchangeTime > 0, "Molten: exchange not happened");
        require(
            block.timestamp < exchangeTime + lockingDuration,
            "Molten: not locked"
        );

        uint256 _deposited = deposited[msg.sender];

        votedForLiquidation[msg.sender] = true;
        totalVotesForLiquidation += _deposited;
    }

    function withdrawVoteForLiquidation() external {
        require(deposited[msg.sender] > 0, "Molten: no voting power");
        require(exchangeTime > 0, "Molten: exchange not happened");
        require(
            block.timestamp < exchangeTime + lockingDuration,
            "Molten: not locked"
        );

        uint256 _deposited = deposited[msg.sender];

        delete votedForLiquidation[msg.sender];
        totalVotesForLiquidation -= _deposited;
    }
}