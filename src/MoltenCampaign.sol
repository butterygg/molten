// SPDX-License-Identifier: UNLICENSED
// solhint-disable not-rely-on-time
pragma solidity ^0.8.17;

import {MToken} from "./MToken.sol";
import {IERC20Votes} from "./interfaces/IERC20Votes.sol";

contract MoltenCampaignMarket {
    IERC20Votes public daoToken;
    // Threshold in daoToken-weis.
    uint256 public threshold;

    constructor(address daoTokenAddress, uint256 _threshold) {
        daoToken = IERC20Votes(daoTokenAddress);
        threshold = _threshold;
    }
}

contract MoltenCampaign {
    address public representative;
    MoltenCampaignMarket public market;

    uint256 public totalDeposited;
    mapping(address => uint256) public deposited;

    constructor(address marketAddress) {
        representative = msg.sender;
        market = MoltenCampaignMarket(marketAddress);
    }

    function _getDaoToken() private view returns (IERC20Votes) {
        return IERC20Votes(market.daoToken());
    }

    function deposit(uint256 amount) public {
        deposited[msg.sender] += amount;
        totalDeposited += amount;

        _getDaoToken().transferFrom(msg.sender, address(this), amount);
    }

    function refund() public {
        uint256 _deposited = deposited[msg.sender];

        deposited[msg.sender] = 0;
        totalDeposited -= _deposited;

        _getDaoToken().transferFrom(address(this), msg.sender, _deposited);
    }
}
