// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MoltenFundraiser} from "../src/MoltenFundraiser.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

abstract contract MoltenFundraiserTestBase is Test {
    ERC20PresetMinterPauser public daoToken;
    MoltenFundraiser public moltenFundraiser;
    address public daoTreasuryAddress = address(0x1);

    ERC20PresetMinterPauser public depositToken;
    address public depositorAddress = address(0x2);

    function setUp() public virtual {
        daoToken = new ERC20PresetMinterPauser("DAO governance token", "GT");
        depositToken = new ERC20PresetMinterPauser("Stable token", "BAI");
        moltenFundraiser = new MoltenFundraiser(
            address(daoToken),
            365 days,
            address(depositToken),
            daoTreasuryAddress
        );
        vm.label(daoTreasuryAddress, "DAO treasury");
        vm.label(depositorAddress, "Depositor");
        vm.label(address(moltenFundraiser), "Molten fundraiser");
    }
}

contract MoltenFundraiserTest is MoltenFundraiserTestBase {
    function testConstructor() public {
        assertEq(moltenFundraiser.lockingDuration(), 365 days);
    }

    function testDepositMissingFunds() public {
        depositToken.mint(depositorAddress, 1000 * 10**18);

        vm.expectRevert();
        vm.prank(depositorAddress);
        moltenFundraiser.deposit(1000 * 10**18);
    }

    function testExchangeMissingFunds() public {
        depositToken.mint(depositorAddress, 1000 * 10**18);
        vm.prank(depositorAddress);
        depositToken.approve(address(moltenFundraiser), 1000 * 10**18);
        vm.prank(depositorAddress);
        moltenFundraiser.deposit(1000 * 10**18);

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        vm.prank(daoTreasuryAddress);
        moltenFundraiser.exchange(20);
    }

    function testClaimBlocked() public {
        vm.expectRevert("Molten: exchange not happened");
        vm.prank(depositorAddress);
        moltenFundraiser.claimMTokens();
    }
}

contract MoltenFundraiserDepositTest is MoltenFundraiserTestBase {
    function setUp() public override {
        super.setUp();

        depositToken.mint(depositorAddress, 1000 * 10**18);
        vm.prank(depositorAddress);
        depositToken.approve(address(moltenFundraiser), 1000 * 10**18);

        vm.prank(depositorAddress);
        moltenFundraiser.deposit(1000 * 10**18);
    }

    function testRecordsDeposit() public {
        assertEq(moltenFundraiser.deposited(depositorAddress), 1000 * 10**18);
    }

    function testIncreasesTotalDeposits() public {
        depositToken.mint(address(0x234), 234 * 10**18);
        vm.prank(address(0x234));
        depositToken.approve(address(moltenFundraiser), 234 * 10**18);
        vm.prank(address(0x234));
        moltenFundraiser.deposit(234 * 10**18);

        assertEq(moltenFundraiser.totalDeposited(), 1234 * 10**18);
    }
}

abstract contract MoltenFundraiserExchangeTestBase is MoltenFundraiserTestBase {
    uint256 public initialDaoTreasuryDepositBalance;
    uint256 public initialTotalDesposits;

    function setUp() public virtual override {
        super.setUp();

        daoToken.mint(daoTreasuryAddress, 4242 * 10**18);
        vm.prank(daoTreasuryAddress);
        daoToken.approve(address(moltenFundraiser), type(uint256).max);

        depositToken.mint(depositorAddress, 1000 * 10**18);
        vm.prank(depositorAddress);
        depositToken.approve(address(moltenFundraiser), 1000 * 10**18);

        initialDaoTreasuryDepositBalance = depositToken.balanceOf(
            daoTreasuryAddress
        );

        vm.prank(depositorAddress);
        moltenFundraiser.deposit(1000 * 10**18);
        vm.prank(daoTreasuryAddress);
        moltenFundraiser.exchange(20);
    }
}

contract MoltenFundraiserExchangeTest is MoltenFundraiserExchangeTestBase {
    function testSetExchangeTime() public {
        assert(moltenFundraiser.exchangeTime() > 0);
    }

    function testTransfersDaoTokensToFundraiser() public {
        assertEq(daoToken.balanceOf(address(moltenFundraiser)), 50 * 10**18);
    }

    function testTransfersDepositsToDaoTreasury() public {
        assertEq(depositToken.balanceOf(address(moltenFundraiser)), 0);
        assertEq(
            depositToken.balanceOf(daoTreasuryAddress) -
                initialDaoTreasuryDepositBalance,
            1000 * 10**18
        );
    }

    function testRepeatedDepositFails() public {
        vm.expectRevert("Molten: exchange happened");
        vm.prank(depositorAddress);
        moltenFundraiser.deposit(1000);
    }

    function testRepeatedExchangeFails() public {
        vm.expectRevert("Molten: exchange happened");
        vm.prank(daoTreasuryAddress);
        moltenFundraiser.exchange(20);
    }

    function testMintsMTokens() public {
        assertEq(moltenFundraiser.totalSupply(), (1000 / 20) * 10**18);
    }
}

contract MoltenFundraiserClaimTest is MoltenFundraiserExchangeTestBase {
    function setUp() public override {
        super.setUp();

        vm.prank(depositorAddress);
        moltenFundraiser.claimMTokens();
    }

    function testTransfersToDepositor() public {
        assertEq(moltenFundraiser.balanceOf(address(moltenFundraiser)), 0);
        assertEq(
            moltenFundraiser.balanceOf(depositorAddress),
            (1000 / 20) * 10**18
        );
    }
}
