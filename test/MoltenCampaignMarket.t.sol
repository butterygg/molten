// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {ERC20VotesMintable} from "./helpers/ERC20VotesMintable.sol";
import {MoltenCampaignMarket} from "../src/MoltenCampaign.sol";

contract CreationTest is Test {
    ERC20VotesMintable daoToken;

    function setUp() public {
        daoToken = new ERC20VotesMintable("DAO governance token", "GT");
        vm.label(address(daoToken), "DAO governance token");
    }

    function testHasDaoToken() public {
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            1
        );

        assertEq(address(mcm.daoToken()), address(daoToken));
    }

    function testHasThreshold(uint256 threshold) public {
        MoltenCampaignMarket mcm = new MoltenCampaignMarket(
            address(daoToken),
            threshold
        );

        assertEq(mcm.threshold(), threshold);
    }
}
