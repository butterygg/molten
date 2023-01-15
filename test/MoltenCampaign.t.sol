// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {ERC20VotesMintableMock, ERC20VotesMintableFailedMock} from "./helpers/ERC20VotesMintable.sol";
import {MoltenCampaign, MoltenCampaignMarket} from "../src/MoltenCampaign.sol";

contract CreationTest is Test {
    MoltenCampaignMarket mcm;
    ERC20VotesMintableMock daoToken;
    uint256 threshold;

    function setUp() public {
        daoToken = new ERC20VotesMintableMock("DAO governance token", "GT");
        threshold = 1;
        mcm = new MoltenCampaignMarket(address(daoToken), threshold);
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
    ERC20VotesMintableMock daoToken;
    uint256 threshold;
    address representative = address(0x123);
    MoltenCampaign mc;

    function setUp() public virtual {
        daoToken = new ERC20VotesMintableMock("DAO governance token", "GT");
        threshold = 1;
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            threshold);
        vm.prank(representative);
        mc = new MoltenCampaign(address(mcm));
    }
}

abstract contract TestBaseFailing is Test {
    ERC20VotesMintableFailedMock daoToken;
    uint256 threshold;
    address representative = address(0x123);
    MoltenCampaign mc;

    function setUp() public virtual {
        daoToken = new ERC20VotesMintableFailedMock("DAO governance token", "GT");
        threshold = 1;
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            threshold);
        vm.prank(representative);
        mc = new MoltenCampaign(address(mcm));
    }
}

contract DepositTest is TestBase {
    address depositor;
    address depositor2;

    function setUp() public override {
        super.setUp();

        depositor = address(0x331);
        depositor2 = address(0x332);
    }

    function testSuccessfulDepositUpdatesDeposited() public {
        vm.prank(depositor);
        mc.deposit(333);
        
        assertEq(mc.deposited(depositor), 333);
    }

    function testSuccessfulDepositsUpdatesTotalDeposited() public {
        vm.prank(depositor);
        mc.deposit(333);

        vm.prank(depositor2);
        mc.deposit(222);
        
        assertEq(mc.totalDeposited(), 555);
    }

    function testSuccessfulDepositCallsTransfer() public {
        vm.prank(depositor);
        mc.deposit(333);

        (address from, address to, uint256 amount) = daoToken.transferFromCalledWith();
        assertEq(from, depositor);
        assertEq(to, address(mc));
        assertEq(amount, 333);
    }
}
    
contract DepositFailTest is TestBaseFailing {
    address depositor;
    address depositor2;

    function setUp() public override {
        super.setUp();

        depositor = address(0x331);
        depositor2 = address(0x332);
    }
    function testUnsuccessfulDepositDoesntUpdate() public {
        vm.prank(depositor);
        vm.expectRevert("ERC20VotesMintableFailedMock transferFrom");
        mc.deposit(333);

        assertEq(mc.deposited(depositor), 0);
        assertEq(mc.totalDeposited(), 0);
    }
}

contract RefundTest is TestBase {
    address depositor;
    address depositor2;

    function setUp() public override {
        super.setUp();

        depositor = address(0x331);
        depositor2 = address(0x332);

        vm.prank(depositor);
        mc.deposit(333);
        vm.prank(depositor2);
        mc.deposit(222);
    }

    function testSuccessfulRefundUpdatesDeposited() public {
        vm.prank(depositor);
        mc.refund();
        
        assertEq(mc.deposited(depositor), 0);
    }

    function testSuccessfulDepositsUpdatesTotalDeposited() public {
        vm.prank(depositor);
        mc.refund();

        vm.prank(depositor2);
        mc.refund();
        
        assertEq(mc.totalDeposited(), 0);
    }

    function testSuccessfulRefundCallsTransfer() public {
        vm.prank(depositor);
        mc.refund();

        (address from, address to, uint256 amount) = daoToken.transferFromCalledWith();
        assertEq(from, address(mc));
        assertEq(to, depositor);
        assertEq(amount, 333);
    }
}
