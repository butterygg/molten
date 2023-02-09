// SPDX-License-Identifier: UNLICENSED
// solhint-disable not-rely-on-time
pragma solidity ^0.8.17;

import {MToken} from "../../src/MToken.sol";
import {MoltenElection} from "../../src/MoltenCampaign.sol";
import {IERC20Votes} from "../../src/interfaces/IERC20Votes.sol";

contract MoltenElectionMock {
    IERC20Votes public daoToken;
    // Threshold in daoToken-weis.
    uint256 public threshold;
    uint128 public duration;
    uint128 public cooldownDuration;
    bool public ended = false;

    struct __EndCall {
        address _sender;
    }
    __EndCall public __endCalledWith;

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

    function end() public {
        __endCalledWith = __EndCall(msg.sender);
    }
}

contract MoltenCampaignMock {
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

    function __stubTotalStaked(uint256 _totalStaked) public {
        totalStaked = _totalStaked;
    }

    function __stubCooldownEnd(uint256 _cooldownEnd) public {
        cooldownEnd = _cooldownEnd;
    }
}
