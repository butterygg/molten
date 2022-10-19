// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./access/Churner.sol";
import "./oracle/v2/UniV2OracleLib.sol";
import "./oracle/v3/UniV3OracleConsulter.sol";

contract mToken is Churner, ERC20Votes {
    uint256 lockEnd;
    uint256 stableMax;

    IERC20 public trustedStableToken;
    IERC20 public govToken;
    bool private isV3Token;

    uint256 public totalStableDeposits = 0;
    mapping(address => uint256) public stableDeposits;
    address[] public depositors;

    constructor(
        address _governor,
        address _delegator,
        address stableToken,
        address _govToken,
        bool _isV3Token
    ) Churner(_governor, _delegator) {
        trustedStableToken = IERC20(stableToken);
        govToken = IERC20(_govToken);
        isV3Token = _isV3Token;
    }

    function setStableToken(address newStableToken)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        trustedStableToken = IERC20(newStableToken);
    }

    function approveStable(uint256 amount) public {
        require(
            _approveToken(trustedStableToken, amount),
            "mToken: stable token approval not required"
        );
    }

    function depositStable(uint256 amount) public {
        require(
            totalStableDeposits <= stableMax,
            "mToken: max stable deposits reached"
        );
        require(
            trustedStableToken.allowance(msg.sender, address(this)) >= amount,
            "mToken: insufficient allowance for deposit"
        );
        require(
            trustedStableToken.balanceOf(msg.sender) >= amount,
            "mToken: insufficient balance for deposit"
        );

        if (stableDeposits[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        stableDeposits[msg.sender] += amount;

        trustedStableToken.transferFrom(msg.sender, address(this), amount);
    }

    function refundStable(uint256 amount) public {
        require(
            stableDeposits[msg.sender] >= amount,
            "mToken: Insufficient balance for refund"
        );

        stableDeposits[msg.sender] -= amount;

        trustedStableToken.transfer(msg.sender, amount);
    }

    function approveGovToken(uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _approveToken(govToken, amount),
            "mToken: gov token approval not required"
        );
    }

    function exchange(uint256 rate) public onlyRole(GOVERNOR) {
        govToken.transferFrom(msg.sender, address(this), amount);
    }

    function _approveToken(IERC20 _token, uint256 _amount)
        private
        returns (bool result)
    {
        uint256 currentAllowance = _token.allowance(msg.sender, address(this));

        if (currentAllowance < _amount) return false;
        result = true;

        _token.approve(address(this), currentAllowance + _amount);
    }
}
