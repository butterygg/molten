// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {ERC20VotesMintable} from "./helpers/ERC20VotesMintable.sol";
import {MoltenCampaignMarket, MoltenCampaign} from "../src/MoltenCampaign.sol";

contract CreationTest is Test {
    ERC20VotesMintable public daoToken;

    function setUp() public {
        daoToken = new ERC20VotesMintable("DAO governance token", "GT");
        vm.label(address(daoToken), "DAO governance token");
    }

    function testHasDaoToken() public {
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            1,
            1
        );

        assertEq(address(mcm.daoToken()), address(daoToken));
    }

    function testHasThreshold(uint256 threshold) public {
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            threshold,
            1
        );

        assertEq(mcm.threshold(), threshold);
    }

    function testHasDuration(uint32 duration) public {
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            1,
            duration
        );

        assertEq(mcm.duration(), duration);
    }
}

contract MakeCampaignTest is Test {
    MoltenCampaignMarket public mcm;
    ERC20VotesMintable public daoToken;
    uint256 public threshold;
    uint32 public duration;

    function setUp() public {
        daoToken = new ERC20VotesMintable("DAO governance token", "GT");
        threshold = 1;
        duration = 1;
        mcm = new MoltenCampaignMarket(address(daoToken), threshold, duration);
    }

    function testHasMarket() public {
        MoltenCampaign mc = mcm.makeCampaign();

        assertEq(address(mc.market()), address(mcm));
    }

    function testHasRepresentative() public {
        vm.prank(address(0x123));
        MoltenCampaign mc = mcm.makeCampaign();

        assertEq(mc.representative(), address(0x123));
    }

    function testHasMToken() public {
        MoltenCampaign mc = mcm.makeCampaign();

        assertTrue(address(mc.mToken()) != address(0x0));
    }

    function testMTokenOwnerIsCampaign() public {
        MoltenCampaign mc = mcm.makeCampaign();

        // We could test this with a mock of transferOwnership but it's simple
        // enough here to call the actual function.
        assertEq(mc.mToken().owner(), address(mc));
    }
}
