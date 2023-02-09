// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MoltenCampaign, MoltenElection} from "../src/MoltenCampaign.sol";
import {MToken} from "../src/MToken.sol";
import {ERC20VotesMintable} from "./helpers/ERC20VotesMintable.sol";
import {ERC20VotesMintableMock} from "./helpers/ERC20VotesMintable.sol";
import {MTokenMock} from "./helpers/MTokenMock.sol";
import {MoltenElectionMock} from "./helpers/MoltenCampaignMock.sol";

abstract contract TestBase is Test {
    uint256 public threshold = 100;
    uint128 public duration = 60;
    uint128 public cooldownDuration = 15;
    address public delegate = address(0x123);
    string public delegateName = "deldel";
    MoltenCampaign public campaign;

    ERC20VotesMintableMock public daoToken;
    MTokenMock public mToken;

    function setUp() public virtual {
        daoToken = new ERC20VotesMintableMock("DAO governance token", "GT");
        MoltenElection election = new MoltenElection(
            address(daoToken),
            threshold,
            duration,
            cooldownDuration
        );
        vm.prank(delegate);
        mToken = new MTokenMock(
            string.concat("Molten ", daoToken.name()),
            string.concat("m", daoToken.symbol(), "-", delegateName),
            address(this)
        );
        campaign = new MoltenCampaign(
            delegate,
            address(election),
            address(mToken)
        );
        mToken.transferOwnership(address(campaign));
    }

    function setFailTransfer() public virtual {
        daoToken.__setFail();
    }

    function unsetFailTransfer() public virtual {
        daoToken.__unsetFail();
    }

    function setFailMint() public virtual {
        mToken.__setFail();
    }

    function unsetFailMint() public virtual {
        mToken.__unsetFail();
    }
}

contract StakeTest is TestBase {
    address public staker = address(0x331);
    address public staker2 = address(0x332);

    function setUp() public override {
        super.setUp();

        vm.prank(staker);
        campaign.stake(333);
    }

    function testStakeUpdatesStaked() public {
        assertEq(campaign.staked(staker), 333);
    }

    function testStakeUpdatesTotalStaked() public {
        vm.prank(staker2);
        campaign.stake(222);

        assertEq(campaign.totalStaked(), 555);
    }

    function testStakeCallsTransfer() public {
        (address from, address to, uint256 amount) = daoToken
            .__transferFromCalledWith();
        assertEq(from, staker);
        assertEq(to, address(campaign));
        assertEq(amount, 333);
    }

    function testStakeMintsMTokens() public {
        (address _sender, address to, uint256 amount) = mToken
            .__mintCalledWith();
        assertEq(_sender, mToken.owner());
        assertEq(to, staker);
        assertEq(amount, 333);
    }

    function testStakeResetsCooldown() public {
        assertEq(campaign.cooldownEnd(), block.timestamp + cooldownDuration);
    }
}

contract CantTransferStakeTest is TestBase {
    address public staker = address(0x331);

    function setUp() public override {
        super.setUp();

        setFailTransfer();
    }

    function testWrongStakeReverts() public {
        vm.prank(staker);
        vm.expectRevert("ERC20VMFM transferFrom");
        campaign.stake(333);
    }
}

contract CantMintStakeTest is TestBase {
    address public staker = address(0x331);

    function setUp() public override {
        super.setUp();

        setFailMint();
    }

    function testWrongStakeReverts() public {
        vm.prank(staker);
        vm.expectRevert("MTFM mint");
        campaign.stake(333);
    }
}

contract UnstakeTest is TestBase {
    address public staker = address(0x331);
    address public staker2 = address(0x332);

    function setUp() public override {
        super.setUp();

        // We call stake as a means to update the `totalStaked` and `staked`
        // states.
        vm.prank(staker);
        campaign.stake(333);
        vm.prank(staker2);
        campaign.stake(222);
        vm.prank(staker);
        campaign.unstake();
    }

    function testUnstakeUpdatesStaked() public {
        assertEq(campaign.staked(staker), 0);
    }

    function testUnstakeUpdatesTotalStaked() public {
        vm.prank(staker2);
        campaign.unstake();

        assertEq(campaign.totalStaked(), 0);
    }

    function testUnstakeCallsTransfer() public {
        (address from, address to, uint256 amount) = daoToken
            .__transferFromCalledWith();
        assertEq(from, address(campaign));
        assertEq(to, staker);
        assertEq(amount, 333);
    }

    function testUnstakeBurnsMTokens() public {
        (address _sender, address to, uint256 amount) = mToken
            .__burnCalledWith();
        assertEq(_sender, mToken.owner());
        assertEq(to, staker);
        assertEq(amount, 333);
    }

    function testUnstakeResetsCooldown() public {
        assertEq(campaign.cooldownEnd(), block.timestamp + cooldownDuration);
    }
}

contract UnstakeNoStakeTest is TestBase {
    address public staker = address(0x331);

    function testUnstakeReverts() public {
        vm.prank(staker);
        vm.expectRevert("Molten: unstake 0");
        campaign.unstake();
    }
}

contract CantTransferUnstakeTest is TestBase {
    address public staker = address(0x331);

    function setUp() public override {
        super.setUp();

        vm.prank(staker);
        campaign.stake(333);
        setFailTransfer();
    }

    function testWrongUnstakeReverts() public {
        vm.prank(staker);
        vm.expectRevert("ERC20VMFM transferFrom");
        campaign.unstake();
    }
}

contract CantBurnUnstakeTest is TestBase {
    address public staker;

    function setUp() public override {
        super.setUp();

        staker = address(0x331);
        vm.prank(staker);
        campaign.stake(333); // Set up MoltenCampaign state.
        setFailMint();
    }

    function testWrongUntakeReverts() public {
        vm.prank(staker);
        vm.expectRevert("MTFM burn");
        campaign.unstake();
    }
}

contract CantTakeOfficeTest is TestBase {
    address public staker = address(0x331);

    function testNoTresholdCantTakeOffice() public {
        vm.expectRevert("Molten: threshold not reached");
        campaign.takeOffice();
    }

    function testCooldownNotEndedCantTakeOffice(uint256 stake) public {
        vm.assume(stake >= threshold);

        vm.prank(staker);
        campaign.stake(stake);

        vm.expectRevert("Molten: cooldown ongoing");
        campaign.takeOffice();
    }

    function testTresholdAndCooldownOkCanTakeOffice(
        uint256 stake,
        uint256 blockTimestamp
    ) public {
        vm.assume(stake >= threshold);

        vm.prank(staker);
        campaign.stake(stake);

        vm.assume(blockTimestamp >= campaign.cooldownEnd());

        vm.warp(blockTimestamp);
        campaign.takeOffice();
    }
}

contract TakeOfficeTest is TestBase {
    address public staker = address(0x331);
    address public staker2 = address(0x332);
    MoltenElectionMock election;

    function setUp() public override {
        daoToken = new ERC20VotesMintableMock("DAO governance token", "GT");
        election = new MoltenElectionMock(
            address(daoToken),
            threshold,
            duration,
            cooldownDuration
        );
        vm.prank(delegate);
        mToken = new MTokenMock(
            string.concat("Molten ", daoToken.name()),
            string.concat("m", daoToken.symbol(), "-", delegateName),
            address(this)
        );
        campaign = new MoltenCampaign(
            delegate,
            address(election),
            address(mToken)
        );
        mToken.transferOwnership(address(campaign));

        vm.prank(staker);
        campaign.stake(threshold);
        vm.warp(campaign.cooldownEnd());
        campaign.takeOffice();
    }

    function testCantStake() public {
        vm.prank(staker);
        vm.expectRevert("Molten: in office");
        campaign.stake(1);
    }

    function testCantUnstake() public {
        vm.prank(staker);
        vm.expectRevert("Molten: in office");
        campaign.unstake();
    }

    function testEndsElection() public {
        address from = election.__endCalledWith();
        assertEq(from, address(campaign));
    }
}
