// SPDX-License-Identifier: UNLICENSED
// solhint-disable not-rely-on-time
pragma solidity ^0.8.17;

import {MToken} from "./MToken.sol";
import {IERC20Votes} from "./interfaces/IERC20Votes.sol";

contract MoltenElection {
    IERC20Votes public daoToken;
    // Threshold in daoToken-weis.
    uint256 public threshold;
    uint128 public duration;
    uint128 public cooldownDuration;
    bool public ended = false;

    constructor(
        address daoTokenAddress,
        uint256 _threshold,
        uint128 _duration,
        uint128 _cooldownDuration
    ) {
        daoToken = IERC20Votes(daoTokenAddress);
        threshold = _threshold;
        duration = _duration;
        cooldownDuration = _cooldownDuration;
    }

    // 🎨 We could further dependency-inject by having a separate libs
    // MTokenDeployer and MoltenCampaignDeployer which addresses are passed as
    // argument of the constructor/function.
    function makeCampaign(string calldata delegateName)
        external
        returns (MoltenCampaign)
    {
        require(!ended, "Molten: election ended");
        MToken mToken = new MToken(
            string.concat("Molten ", daoToken.name(), " by ", delegateName),
            string.concat("m", daoToken.symbol(), "-", delegateName),
            address(this)
        );
        MoltenCampaign campaign = new MoltenCampaign(
            msg.sender,
            address(this),
            address(mToken)
        );
        mToken.transferOwnership(address(campaign));
        return campaign;
    }

    // [XXX] This needs permission otherwise anyone can end the election. For
    // this, it seems no other solutoin than storing in this contract the list
    // of campaigns.
    function end() public {
        MoltenCampaign campaign = MoltenCampaign(msg.sender);
        require(
            campaign.totalStaked() >= threshold,
            "Molten: threshold not reached"
        );
        require(
            block.timestamp >= campaign.cooldownEnd(),
            "Molten: cooldown not ended"
        );

        ended = true;
    }
}

contract MoltenCampaign {
    // Immutable props.
    address public representative;
    MoltenElection public election;
    MToken public mToken;

    // Mutable props.
    uint256 public totalStaked;
    mapping(address => uint256) public staked;
    uint256 public cooldownEnd;
    bool public inOffice;

    constructor(
        address _representative,
        address electionAddress,
        address mTokenAddress
    ) {
        representative = _representative;
        election = MoltenElection(electionAddress);
        mToken = MToken(mTokenAddress);
    }

    function _getDaoToken() private view returns (IERC20Votes) {
        return IERC20Votes(election.daoToken());
    }

    function _resetCooldown() internal {
        cooldownEnd = block.timestamp + election.cooldownDuration();
    }

    function stake(uint256 amount) public {
        require(!inOffice, "Molten: in office");

        staked[msg.sender] += amount;
        totalStaked += amount;

        mToken.mint(msg.sender, amount);
        _resetCooldown();
        _getDaoToken().transferFrom(msg.sender, address(this), amount);
    }

    function unstake() public {
        uint256 _staked = staked[msg.sender];
        require(!inOffice, "Molten: in office");
        require(_staked > 0, "Molten: unstake 0");

        staked[msg.sender] = 0;
        totalStaked -= _staked;

        mToken.burn(msg.sender, _staked);
        _resetCooldown();
        _getDaoToken().transferFrom(address(this), msg.sender, _staked);
    }

    function takeOffice() public {
        require(
            totalStaked >= election.threshold(),
            "Molten: threshold not reached"
        );
        require(block.timestamp >= cooldownEnd, "Molten: cooldown ongoing");

        inOffice = true;
    }
}
