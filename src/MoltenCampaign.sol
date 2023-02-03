// SPDX-License-Identifier: UNLICENSED
// solhint-disable not-rely-on-time
pragma solidity ^0.8.17;

import {MToken} from "./MToken.sol";
import {IERC20Votes} from "./interfaces/IERC20Votes.sol";

/// [XXX] Rename to MoltenElection
contract MoltenCampaignMarket {
    IERC20Votes public daoToken;
    // Threshold in daoToken-weis.
    uint256 public threshold;
    uint32 public duration;

    constructor(
        address daoTokenAddress,
        uint256 _threshold,
        uint32 _duration
    ) {
        daoToken = IERC20Votes(daoTokenAddress);
        threshold = _threshold;
        duration = _duration;
    }

    // [XXX] We could further dependency-inject by having a separate libs
    // MTokenDeployer and MoltenCampaignDeployer which addresses are passed as
    // argument of the constructor (or the function?).
    function makeCampaign() external returns (MoltenCampaign) {
        MToken mToken = new MToken(
            string.concat("Molten ", daoToken.name()),
            string.concat("m", daoToken.symbol()), // [XXX] Add campaigner (delegate) name
            address(this)
        );
        MoltenCampaign mc = new MoltenCampaign(
            msg.sender,
            address(this),
            address(mToken)
        );
        mToken.transferOwnership(address(mc));
        return mc;
    }
}

contract MoltenCampaign {
    address public representative;
    MoltenCampaignMarket public market;
    MToken public mToken;

    uint256 public totalStaked;
    mapping(address => uint256) public staked;

    // 💜 dumb constructors.
    constructor(
        address _representative,
        address marketAddress,
        address mTokenAddress
    ) {
        representative = _representative;
        market = MoltenCampaignMarket(marketAddress);
        mToken = MToken(mTokenAddress);
    }

    function _getDaoToken() private view returns (IERC20Votes) {
        return IERC20Votes(market.daoToken());
    }

    function stake(uint256 amount) public {
        staked[msg.sender] += amount;
        totalStaked += amount;

        mToken.mint(msg.sender, amount);
        _getDaoToken().transferFrom(msg.sender, address(this), amount);
    }

    function unstake() public {
        uint256 _staked = staked[msg.sender];

        staked[msg.sender] = 0;
        totalStaked -= _staked;
    
        mToken.burn(msg.sender, _staked);
        _getDaoToken().transferFrom(address(this), msg.sender, _staked);
    }
}
