// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Molten.sol";
import "./governance/extensions/MiniGovernorCounting.sol";

contract mToken is Molten, MiniGovernorCounting, ERC20Votes {
    constructor(
        address churnerAddress,
        address oracleAdapterAddress,
        address stableTokenAddress,
        address daoTokenAddress,
        uint256 _stableMax,
        uint256 _lockEnd,
        uint256 _votingDelay,
        uint256 _votingPeriod
    )
        ERC20("mToken", "MT")
        ERC20Permit("mToken")
        MiniGovernorQuorumFraction(55)
        MiniGovernor(_votingDelay, _votingPeriod)
    {
        churner = IChurner(churnerAddress);
        churner.grantRole(DAO, address(this));

        oracleAdapter = IOracleAdapter(oracleAdapterAddress);

        trustedStableToken = IERC20(stableTokenAddress);
        daoToken = IERC20(daoTokenAddress);

        lockStatus = 1;
        stableMax = _stableMax;
        lockEnd = _lockEnd;
    }

    function mintMTokens() public {
        uint256 msgSenderStableTokenBalance = stableDeposits[msg.sender];
        require(
            msgSenderStableTokenBalance != 0,
            "mToken: insufficient Stable Deposits balance"
        );
        stableDeposits[msg.sender] = 0;

        uint256 daoTokensOwed = (msgSenderStableTokenBalance * 10) /
            (currentExchangeRate * 10);
        uint256 contractDaoTokenBalance = daoToken.balanceOf(address(this));
        require(daoTokensOwed <= contractDaoTokenBalance);

        _mint(msg.sender, daoTokensOwed);
    }

    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory // params
    ) internal view virtual override returns (uint256) {
        return getPastVotes(account, blockNumber);
    }

    function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
        return (getPastTotalSupply(blockNumber) * quorumNumerator(blockNumber)) / quorumDenominator();
    }
}
