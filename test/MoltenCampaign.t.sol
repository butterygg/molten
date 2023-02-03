// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MoltenCampaign, MoltenCampaignMarket} from "../src/MoltenCampaign.sol";
import {MToken} from "../src/MToken.sol";
import {ERC20VotesMintable} from "./helpers/ERC20VotesMintable.sol";
import {ERC20VotesMintableMock, ERC20VotesMintableFailedMock} from "./helpers/ERC20VotesMintable.sol";
import {MTokenMock, MTokenFailingMock} from "./helpers/MTokenMock.sol";


abstract contract TestBase is Test {
    ERC20VotesMintableMock public daoToken;
    MTokenMock public mToken;

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
        mToken = new MTokenMock(
            string.concat("Molten ", daoToken.name()),
            string.concat("m", daoToken.symbol()), // [XXX] Add campaigner (delegate) name
            address(this)
        );
        mc = new MoltenCampaign(representative, address(mcm), address(mToken));
        mToken.transferOwnership(address(mc));
    }
}

abstract contract TestBaseFailingTransfer is Test {
    ERC20VotesMintableFailedMock public daoToken;
    MTokenMock public mToken;

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
        mToken = new MTokenMock(
            string.concat("Molten ", daoToken.name()),
            string.concat("m", daoToken.symbol()), // [XXX] Add campaigner (delegate) name
            address(this)
        );
        mc = new MoltenCampaign(representative, address(mcm), address(mToken));
        mToken.transferOwnership(address(mc));
    }
}

abstract contract TestBaseFailingMint is Test {
    ERC20VotesMintableMock public daoToken;
    MTokenFailingMock public mToken;

    uint256 public threshold;
    uint32 public duration;
    address public representative = address(0x123);
    MoltenCampaign public mc;

    function setUp() public virtual {
        daoToken = new ERC20VotesMintableMock(
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
        mToken = new MTokenFailingMock(
            string.concat("Molten ", daoToken.name()),
            string.concat("m", daoToken.symbol()), // [XXX] Add campaigner (delegate) name
            address(this)
        );
        mc = new MoltenCampaign(representative, address(mcm), address(mToken));
        mToken.transferOwnership(address(mc));

        setFail();
    }

    function setFail() public virtual {
        mToken.setFail(); 
    }
    function unsetFail() public virtual {
        mToken.unsetFail(); 
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

    function testStakeUpdatesStaked() public {
        vm.prank(staker);
        mc.stake(333);

        assertEq(mc.staked(staker), 333);
    }

    function testStakeUpdatesTotalStaked() public {
        vm.prank(staker);
        mc.stake(333);

        vm.prank(staker2);
        mc.stake(222);

        assertEq(mc.totalStaked(), 555);
    }

    function testStakeCallsTransfer() public {
        vm.prank(staker);
        mc.stake(333);

        (address from, address to, uint256 amount) = daoToken
            .transferFromCalledWith();
        assertEq(from, staker);
        assertEq(to, address(mc));
        assertEq(amount, 333);
    }

    function testStakeMintsMTokens() public {
        vm.prank(staker);
        mc.stake(333);

        (address _sender, address to, uint256 amount) = mToken.mintCalledWith();
        assertEq(_sender, mToken.owner());
        assertEq(to, staker);
        assertEq(amount, 333);
    }
}

contract CantTransferStakeTest is TestBaseFailingTransfer {
    address public staker;

    function setUp() public override {
        super.setUp();

        staker = address(0x331);
    }

    function testWrongStakeDoesntUpdate() public {
        vm.prank(staker);
        vm.expectRevert("ERC20VMFM transferFrom");
        mc.stake(333);

        assertEq(mc.staked(staker), 0);
        assertEq(mc.totalStaked(), 0);
    }
}

contract CantMintStakeTest is TestBaseFailingMint {
    address public staker;

    function setUp() public override {
        super.setUp();

        staker = address(0x331);
    }

    function testWrongStakeDoesntUpdate() public {
        vm.prank(staker);
        vm.expectRevert("MTFM mint");
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

        // We call stake as a means to update the `totalStaked` and `staked`
        // states.
        vm.prank(staker);
        mc.stake(333);
        vm.prank(staker2);
        mc.stake(222);
    }

    function testUnstakeUpdatesStaked() public {
        vm.prank(staker);
        mc.unstake();
        assertEq(mc.staked(staker), 0);
    }

    function testUnstakeUpdatesTotalStaked() public {
        vm.prank(staker);
        mc.unstake();

        vm.prank(staker2);
        mc.unstake();

        assertEq(mc.totalStaked(), 0);
    }

    function testUnstakeCallsTransfer() public {
        vm.prank(staker);
        mc.unstake();

        (address from, address to, uint256 amount) = daoToken
            .transferFromCalledWith();
        assertEq(from, address(mc));
        assertEq(to, staker);
        assertEq(amount, 333);
    }

    function testUnstakeBurnsMTokens() public {
        vm.prank(staker);
        mc.unstake();

        (address _sender, address to, uint256 amount) = mToken.burnCalledWith();
        assertEq(_sender, mToken.owner());
        assertEq(to, staker);
        assertEq(amount, 333);
    }
}

contract CantTransferUnstakeTest is TestBaseFailingTransfer {
    address public staker;
    address public staker2;

    function setUp() public override {
        super.setUp();

        staker = address(0x331);
        staker2 = address(0x332);
    }

    function testWrongUnstakeDoesntUpdate() public {
        vm.prank(staker);
        vm.expectRevert("ERC20VMFM transferFrom");
        mc.unstake();

        assertEq(mc.staked(staker), 0);
        assertEq(mc.totalStaked(), 0);
    }
}

contract CantMintUnstakeTest is TestBaseFailingMint {
    address public staker;

    function setUp() public override {
        super.setUp();

        unsetFail();
        staker = address(0x331);
        vm.prank(staker);
        mc.stake(333); // Set up MoltenCampaign state.
        setFail();
    }

    function testWrongUntakeDoesntUpdate() public {
        vm.prank(staker);
        vm.expectRevert("MTFM burn");
        mc.unstake();

        assertEq(mc.staked(staker), 333);
        assertEq(mc.totalStaked(), 333);
    }
    
}
