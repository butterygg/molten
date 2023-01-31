// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {ERC20VotesMintableMock, ERC20VotesMintableFailedMock} from "./helpers/ERC20VotesMintable.sol";
import {MoltenCampaign, MoltenCampaignMarket} from "../src/MoltenCampaign.sol";

contract CreationTest is Test {
    MoltenCampaignMarket public mcm;
    ERC20VotesMintableMock public daoToken;
    uint256 public threshold;
    uint32 public duration;

    function setUp() public {
        daoToken = new ERC20VotesMintableMock("DAO governance token", "GT");
        threshold = 1;
        duration = 1;
        mcm = new MoltenCampaignMarket(address(daoToken), threshold, duration);
    }

    function testHasMarket() public {
        MoltenCampaign mc = new MoltenCampaign(address(mcm));

        assertEq(address(mc.market()), address(mcm));
    }

    function testHasRepresentative() public {
        vm.prank(address(0x123));
        MoltenCampaign mc = new MoltenCampaign(address(mcm));

        assertEq(mc.representative(), address(0x123));
    }
}

abstract contract TestBase is Test {
    ERC20VotesMintableMock public daoToken;
    uint256 public threshold;
    uint32 public duration;
    address public representative = address(0x123);
    MoltenCampaign public mc;

    function setUp() public virtual {
        daoToken = new ERC20VotesMintableMock("DAO governance token", "GT");
        threshold = 1;
        duration = 1;
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            threshold,
            duration
        );
        vm.prank(representative);
        mc = new MoltenCampaign(address(mcm));
    }
}

abstract contract TestBaseFailing is Test {
    ERC20VotesMintableFailedMock public daoToken;
    uint256 public threshold;
    uint32 public duration;
    address public representative = address(0x123);
    MoltenCampaign public mc;

    function setUp() public virtual {
        daoToken = new ERC20VotesMintableFailedMock(
            "DAO governance token",
            "GT"
        );
        threshold = 1;
        duration = 1;
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            threshold,
            duration
        );
        vm.prank(representative);
        mc = new MoltenCampaign(address(mcm));
    }
}

contract StakeTest is TestBase {
    address public staker;
    address public staker2;

    function setUp() public override {
        super.setUp();

        staker = address(0x331);
        staker2 = address(0x332);
    }

    function testSuccessfulStakeUpdatesStaked() public {
        vm.prank(staker);
        mc.stake(333);

        assertEq(mc.staked(staker), 333);
    }

    function testSuccessfulStakesUpdatesTotalStaked() public {
        vm.prank(staker);
        mc.stake(333);

        vm.prank(staker2);
        mc.stake(222);

        assertEq(mc.totalStaked(), 555);
    }

    function testSuccessfulStakeCallsTransfer() public {
        vm.prank(staker);
        mc.stake(333);

        (address from, address to, uint256 amount) = daoToken
            .transferFromCalledWith();
        assertEq(from, staker);
        assertEq(to, address(mc));
        assertEq(amount, 333);
    }
}

contract StakeFailTest is TestBaseFailing {
    address public staker;
    address public staker2;

    function setUp() public override {
        super.setUp();

        staker = address(0x331);
        staker2 = address(0x332);
    }

    function testUnsuccessfulStakeDoesntUpdate() public {
        vm.prank(staker);
        vm.expectRevert("ERC20VMFM transferFrom");
        mc.stake(333);

        assertEq(mc.staked(staker), 0);
        assertEq(mc.totalStaked(), 0);
    }
}

contract UnstakeTest is TestBase {
    address public staker;
    address public staker2;

    function setUp() public override {
        super.setUp();

        staker = address(0x331);
        staker2 = address(0x332);

        vm.prank(staker);
        mc.stake(333);
        vm.prank(staker2);
        mc.stake(222);
    }

    function testSuccessfulUnstakeUpdatesStaked() public {
        vm.prank(staker);
        mc.unstake();
        assertEq(mc.staked(staker), 0);
    }

    function testSuccessfulUnstakesUpdateTotalStaked() public {
        vm.prank(staker);
        mc.unstake();

        vm.prank(staker2);
        mc.unstake();

        assertEq(mc.totalStaked(), 0);
    }

    function testSuccessfulUnstakeCallsTransfer() public {
        vm.prank(staker);
        mc.unstake();

        (address from, address to, uint256 amount) = daoToken
            .transferFromCalledWith();
        assertEq(from, address(mc));
        assertEq(to, staker);
        assertEq(amount, 333);
    }
}
