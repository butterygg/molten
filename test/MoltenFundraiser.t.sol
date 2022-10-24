// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MoltenFundraiser} from "../src/MoltenFundraiser.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract MoltenFundraiserTest is Test {
    ERC20PresetMinterPauser public daoToken;
    MoltenFundraiser public moltenFundraiser;
    address public daoTreasuryAddress = address(0x1);

    ERC20PresetMinterPauser public depositToken;
    address public depositorAddress = address(0x2);

    function setUp() public {
        daoToken = new ERC20PresetMinterPauser("DAO governance token", "GT");
        depositToken = new ERC20PresetMinterPauser("Stable token", "BAI");
        moltenFundraiser = new MoltenFundraiser(
            address(daoToken),
            365 days,
            address(depositToken)
        );
        vm.label(daoTreasuryAddress, "DAO treasury");
    }

    function testConstructor() public {
        assertEq(moltenFundraiser.lockingDuration(), 365 days);
    }

    function testExchangeMissingFunds() public {
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        vm.prank(daoTreasuryAddress);
        moltenFundraiser.exchange(1);
    }

    function testExchangeGTReceivedByFundraiser() public {
        daoToken.mint(daoTreasuryAddress, 1000);
        vm.prank(daoTreasuryAddress);
        daoToken.approve(address(moltenFundraiser), 1000);

        vm.prank(daoTreasuryAddress);
        moltenFundraiser.exchange(1000);

        assertEq(daoToken.balanceOf(address(moltenFundraiser)), 1000);
    }

    function testDepositMissingFunds() public {
        depositToken.mint(depositorAddress, 1000);

        vm.expectRevert();
        vm.prank(depositorAddress);
        moltenFundraiser.deposit(1000);
    }

    function testDeposit() public {
        depositToken.mint(depositorAddress, 1000);
        vm.prank(depositorAddress);
        depositToken.approve(address(moltenFundraiser), 1000);

        vm.prank(depositorAddress);
        moltenFundraiser.deposit(1000);
    }
}
