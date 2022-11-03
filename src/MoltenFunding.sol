// SPDX-License-Identifier: UNLICENSED
// solhint-disable not-rely-on-time
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol"; // [TODO] Use an interface.
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

import {MToken} from "./MToken.sol";

contract MoltenFunding is ReentrancyGuard {
    address public candidateAddress;
    address public daoTreasuryAddress;
    MToken public mToken;
    IERC20 public depositToken;
    ERC20Votes public daoToken;

    // ⚠️  This mapping is not emptied on exchange. After exchange, its values
    // are really only what was deposited by a given address.
    mapping(address => uint256) public deposited;
    // ⚠️  Not emptied on exchange.
    uint256 public totalDeposited;

    uint256 public exchangeTime;
    uint256 public exchangeRate;
    uint256 public lockingDuration;

    mapping(address => bool) public mTokensClaimed;

    uint256 public liquidationTime;
    mapping(address => bool) public votedForLiquidation;
    uint256 public totalVotesForLiquidation;

    constructor(
        address daoTokenAddress,
        uint256 _lockingDuration,
        address depositTokenAddress,
        address _daoTreasuryAddress
    ) {
        candidateAddress = msg.sender;
        lockingDuration = _lockingDuration;
        daoToken = ERC20Votes(daoTokenAddress);
        depositToken = IERC20(depositTokenAddress);
        daoTreasuryAddress = _daoTreasuryAddress;

        mToken = new MToken(
            string.concat("Molten ", daoToken.name()),
            string.concat("m", daoToken.symbol()),
            address(this)
        );
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
    function exchange(uint256 _exchangeRate) external nonReentrant {
        uint256 daoTokenTotal = totalDeposited / _exchangeRate;

        require(
            msg.sender == daoTreasuryAddress,
            "Molten: exchange only by DAO"
        );
        require(exchangeTime == 0, "Molten: exchange happened");

        exchangeTime = block.timestamp;
        exchangeRate = _exchangeRate;

        mToken.mint(address(this), daoTokenTotal);
        depositToken.transfer(daoTreasuryAddress, totalDeposited);
        daoToken.transferFrom(msg.sender, address(this), daoTokenTotal);
        daoToken.delegate(candidateAddress);
    }

    function _claimableDaoTokenBalance(address account)
        private
        view
        returns (uint256)
    {
        assert(exchangeRate > 0);

        return deposited[account] / exchangeRate;
    }

    function claimMTokens() external {
        require(deposited[msg.sender] > 0, "Molten: no mToken to claim");
        require(exchangeTime > 0, "Molten: exchange not happened");

        mTokensClaimed[msg.sender] = true;

        // [FIXME] We are not making sure that the total amount of claimable
        // mTokens is going to match exactly the total minted supply.
        mToken.transfer(msg.sender, _claimableDaoTokenBalance(msg.sender));
    }

    /**
     * @notice Sets the contract as liquidated, which allows claiming of DAO
     * governance tokens by mToken holders.
     * ⚠️  Resets delegation to null. After claiming their tokens, token holders
     * may change delegation.
     */
    function liquidate() external {
        bool lockEnded = block.timestamp >= exchangeTime + lockingDuration;
        bool unanimousLiquidationVote = totalVotesForLiquidation ==
            totalDeposited;

        require(exchangeTime > 0, "Molten: exchange not happened");
        require(lockEnded || unanimousLiquidationVote, "Molten: locked");

        liquidationTime = block.timestamp;

        mToken.pause();
        daoToken.delegate(address(0x00));
    }

    function claim() external {
        uint256 mTokenBalance = mToken.balanceOf(msg.sender);
        uint256 unclaimedMTokenBalance = (
            mTokensClaimed[msg.sender]
                ? 0
                : _claimableDaoTokenBalance(msg.sender)
        );
        uint256 claimableBalance = mTokenBalance + unclaimedMTokenBalance;

        require(claimableBalance > 0, "Molten: nothing to claim");
        require(liquidationTime > 0, "Molten: not liquidated");

        mToken.unpause();
        mToken.burn(msg.sender, mTokenBalance);
        mToken.burn(address(this), unclaimedMTokenBalance);
        mToken.pause();
        daoToken.transfer(msg.sender, claimableBalance);
    }

    function voteForLiquidation() external {
        uint256 _deposited = deposited[msg.sender];

        require(deposited[msg.sender] > 0, "Molten: no voting power");
        require(exchangeTime > 0, "Molten: exchange not happened");
        require(
            block.timestamp < exchangeTime + lockingDuration,
            "Molten: not locked"
        );

        votedForLiquidation[msg.sender] = true;
        totalVotesForLiquidation += _deposited;
    }

    function withdrawVoteForLiquidation() external {
        uint256 _deposited = deposited[msg.sender];

        require(deposited[msg.sender] > 0, "Molten: no voting power");
        require(exchangeTime > 0, "Molten: exchange not happened");
        require(
            block.timestamp < exchangeTime + lockingDuration,
            "Molten: not locked"
        );

        delete votedForLiquidation[msg.sender];
        totalVotesForLiquidation -= _deposited;
    }
}
