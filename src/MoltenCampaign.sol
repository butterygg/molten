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
        MToken mToken = new MToken(
            string.concat("Molten ", daoToken.name()),
            string.concat("m", daoToken.symbol(), "-", delegateName),
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
    // Immutable props.
    address public representative;
    MoltenElection public election;
    MToken public mToken;

    // Mutable props.
    uint256 public totalStaked;
    mapping(address => uint256) public staked;
    uint256 public cooldownEnd;

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
        staked[msg.sender] += amount;
        totalStaked += amount;

        mToken.mint(msg.sender, amount);
        _resetCooldown();
        _getDaoToken().transferFrom(msg.sender, address(this), amount);
    }

    function unstake() public {
        uint256 _staked = staked[msg.sender];
        require(_staked > 0, "Molten: unstake 0");

        staked[msg.sender] = 0;
        totalStaked -= _staked;

        mToken.burn(msg.sender, _staked);
        _resetCooldown();
        _getDaoToken().transferFrom(address(this), msg.sender, _staked);
    }
}
