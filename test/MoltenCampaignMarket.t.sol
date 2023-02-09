// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MoltenElection, MoltenCampaign} from "../src/MoltenCampaign.sol";
import {ERC20VotesMintable} from "./helpers/ERC20VotesMintable.sol";
import {MoltenCampaignMock} from "./helpers/MoltenCampaignMock.sol";

contract CreationTest is Test {
    ERC20VotesMintable public daoToken;

    function setUp() public {
        daoToken = new ERC20VotesMintable("DAO governance token", "GT");
        vm.label(address(daoToken), "DAO governance token");
    }

    function testHasDaoToken() public {
        MoltenElection election = new MoltenElection(
            address(daoToken),
            1,
            1,
            1
        );

        assertEq(address(election.daoToken()), address(daoToken));
    }

    function testHasThreshold(uint256 threshold) public {
        MoltenElection election = new MoltenElection(
            address(daoToken),
            threshold,
            1,
            1
        );

        assertEq(election.threshold(), threshold);
    }

    function testHasDuration(uint32 duration) public {
        MoltenElection election = new MoltenElection(
            address(daoToken),
            1,
            duration,
            1
        );

        assertEq(election.duration(), duration);
    }

    function testHasCooldownDuration(uint32 cooldownDuration) public {
        MoltenElection election = new MoltenElection(
            address(daoToken),
            1,
            1,
            cooldownDuration
        );

        assertEq(election.cooldownDuration(), cooldownDuration);
    }

    function testNotEnded() public {
        MoltenElection election = new MoltenElection(
            address(daoToken),
            1,
            1,
            1
        );

        assertFalse(election.ended());
    }
}

contract MakeCampaignTest is Test {
    MoltenElection public election;
    ERC20VotesMintable public daoToken;

    function setUp() public {
        daoToken = new ERC20VotesMintable("DAO governance token", "GT");
        election = new MoltenElection(address(daoToken), 1, 1, 1);
    }

    function testHasElection() public {
        MoltenCampaign campaign = election.makeCampaign("butter");

        assertEq(address(campaign.election()), address(election));
    }

    function testHasRepresentative() public {
        vm.prank(address(0x123));
        MoltenCampaign campaign = election.makeCampaign("butter");

        assertEq(campaign.representative(), address(0x123));
    }

    function testHasMToken() public {
        MoltenCampaign campaign = election.makeCampaign("butter");

        assertTrue(address(campaign.mToken()) != address(0x0));
    }

    function testMTokenOwnerIsCampaign() public {
        MoltenCampaign campaign = election.makeCampaign("butter");

        // We could test this with a mock of transferOwnership but it's simple
        // enough here to call the actual function.
        assertEq(campaign.mToken().owner(), address(campaign));
    }

    function testMTokenName() public {
        MoltenCampaign campaign = election.makeCampaign("butter");

        assertEq(campaign.mToken().symbol(), "mGT-butter");
    }
}

contract EndTest is Test {
    ERC20VotesMintable public daoToken;
    MoltenCampaignMock public campaign;

    function setUp() public {
        daoToken = new ERC20VotesMintable("DAO governance token", "GT");
        campaign = new MoltenCampaignMock(
            address(0xdeadbeef1),
            address(0xdeadbeef2),
            address(0xdeadbeef3)
        );
    }

    function testRequiresThresholdReached(uint256 threshold) public {
        vm.assume(threshold >= 1);
        MoltenElection election = new MoltenElection(
            address(daoToken),
            threshold,
            1,
            1
        );
        campaign.__stubTotalStaked(0);

        vm.prank(address(campaign));
        vm.expectRevert("Molten: threshold not reached");
        election.end();
    }

    function testRequiresCooldownEnded(
        uint256 threshold,
        uint128 cooldownDuration
    ) public {
        vm.assume(threshold >= 1);
        MoltenElection election = new MoltenElection(
            address(daoToken),
            threshold,
            1,
            cooldownDuration
        );
        campaign.__stubTotalStaked(threshold);
        campaign.__stubCooldownEnd(block.timestamp + 1);

        vm.prank(address(campaign));
        vm.expectRevert("Molten: cooldown not ended");
        election.end();
    }

    function testSetsEnded(uint256 threshold, uint128 cooldownDuration) public {
        vm.assume(threshold >= 1);
        MoltenElection election = new MoltenElection(
            address(daoToken),
            threshold,
            1,
            cooldownDuration
        );
        campaign.__stubTotalStaked(threshold);
        campaign.__stubCooldownEnd(block.timestamp - 1);

        vm.prank(address(campaign));
        election.end();

        assertTrue(election.ended());
    }
}
