// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./access/MoltenAccess.sol";
import "./access/Mutex.sol";
import "./oracle/IOracleAdapter.sol";

abstract contract Molten is MoltenAccess, Mutex {
    uint256 public lockEnd;
    uint256 public stableMax;
    uint256 public currentExchangeRate;

    IERC20 public trustedStableToken;
    IERC20 public daoToken;

    IOracleAdapter public oracleAdapter;

    uint256 public totalStableDeposits = 0;

    mapping(address => uint256) public stableDeposits;
    mapping(address => uint256) public fireDelegatorVotes;

    function setStableMax(uint256 newStableMax)
        external
        onlyRole(0x00) // DEFAULT_ADMIN_ROLE
    {
        stableMax = newStableMax;
    }

    function setLockEnd(uint256 newLockEnd)
        external
        onlyRole(0x00) // DEFAULT_ADMIN_ROLE
    {
        lockEnd = newLockEnd;
    }

    function setStableToken(address newStableToken)
        public
        onlyRole(0x00) // DEFAULT_ADMIN_ROLE
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

        stableDeposits[msg.sender] += amount;
        totalStableDeposits += amount;

        oracleAdapter.update();
        trustedStableToken.transferFrom(msg.sender, address(this), amount);
    }

    function refundStable(uint256 amount) public {
        require(
            stableDeposits[msg.sender] >= amount,
            "mToken: Invalid requested amount for refund"
        );

        stableDeposits[msg.sender] -= amount;
        totalStableDeposits -= amount;

        oracleAdapter.update();
        trustedStableToken.transfer(msg.sender, amount);
    }

    function approvedaoToken(uint256 amount) public onlyRole(DAO) {
        require(
            _approveToken(daoToken, amount),
            "mToken: gov token approval not required"
        );
    }

    function exchange(uint256 premium, uint8 premium_decimals)
        public
        isNotLocked
        onlyRole(DAO)
    {
        require(premium_decimals > 0, "mToken: invalid decimals");
        require(totalStableDeposits < stableMax);

        uint256 totalStableDepositsBefore = totalStableDeposits;
        totalStableDeposits = 0;

        oracleAdapter.update();
        currentExchangeRate = oracleAdapter.consult(10**IERC20Metadata(address(daoToken)).decimals());

        uint256 daoTokenDecimals = IERC20Metadata(address(daoToken)).decimals();
        uint256 stableTokenDecimals = IERC20Metadata(address(trustedStableToken)).decimals();

        uint256 conversionNumerator;
        if (daoTokenDecimals != stableTokenDecimals) {
            conversionNumerator = calculateConversionNumerator(
                IERC20Metadata(address(daoToken)).decimals(),
                IERC20Metadata(address(trustedStableToken)).decimals(),
                totalStableDepositsBefore
            );
        } else {
            conversionNumerator = totalStableDepositsBefore;
        }

        daoToken.transferFrom(
            msg.sender,
            address(this),
            ((conversionNumerator * premium) /
                (currentExchangeRate * 10**premium_decimals))
        );
        trustedStableToken.transfer(msg.sender, totalStableDepositsBefore);
    }

    function calculateConversionNumerator(
        uint256 daoTokenDecimals,
        uint256 stableTokenDecimals,
        uint256 stableDepositsAmount
    ) private pure returns (uint256 conversionNumerator) {
        uint256 exchangeRateDecimalsDifference;

        if (daoTokenDecimals > stableTokenDecimals) {
            exchangeRateDecimalsDifference =
                daoTokenDecimals -
                stableTokenDecimals;

            conversionNumerator =
                stableDepositsAmount *
                10**exchangeRateDecimalsDifference;
        } else {
            exchangeRateDecimalsDifference =
                stableTokenDecimals -
                daoTokenDecimals;

            conversionNumerator =
                stableDepositsAmount /
                10**exchangeRateDecimalsDifference;
        }
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
