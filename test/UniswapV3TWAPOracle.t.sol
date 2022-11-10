// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "uniswap-v3-core/interfaces/pool/IUniswapV3PoolDerivedState.sol";

import {OracleConsulter} from "../src/oracle/libraries/OracleConsulter.sol";
import {FullMath} from "../src/oracle/libraries/math/NewFullMath.sol";

contract OracleLibraryTest is Test {
    uint256 public mainnetFork;

    function setUp() public {
        string memory mainnetRPCUrl = vm.envString("MAINNET_RPC_URL");
        mainnetFork = vm.createFork(mainnetRPCUrl, 15895873);
    }

    function testConsultWithForkManualChained() public {
        vm.selectFork(mainnetFork);

        // ERC20s
        address mainnetDai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address mainnetWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address mainnetAave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

        // Pools
        address mainnetDaiWETHPool = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
        address mainnetAaveWETHPool = 0x5aB53EE1d50eeF2C1DD3d5402789cd27bB52c1bB;

        uint128 oneDai = 1 ether;
        uint256 wethOutput = OracleConsulter.consult(
            mainnetDaiWETHPool,
            14400,
            oneDai,
            mainnetDai,
            mainnetWETH
        );
        uint256 aaveOutput = OracleConsulter.consult(
            mainnetAaveWETHPool,
            14400,
            uint128(wethOutput),
            mainnetWETH,
            mainnetAave
        );

        assertEq(aaveOutput, 10875160537248185); // ~0.0109 AAVE/DAI
    }

    function testConsultWithForkChained(uint256 baseAmount) public {
        vm.selectFork(mainnetFork);
        uint128 _baseAmount = uint128(
            bound(baseAmount, 1 ether, type(uint128).max)
        );

        // ERC20s
        address mainnetDai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address mainnetWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address mainnetAave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

        // Pools
        address mainnetDaiWETHPool = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
        address mainnetAaveWETHPool = 0x5aB53EE1d50eeF2C1DD3d5402789cd27bB52c1bB;

        uint128 daiInput = _baseAmount;

        address[] memory tokenAddressRoute = new address[](3);
        tokenAddressRoute[0] = mainnetDai;
        tokenAddressRoute[1] = mainnetWETH;
        tokenAddressRoute[2] = mainnetAave;

        address[] memory poolRoute = new address[](2);
        poolRoute[0] = mainnetDaiWETHPool;
        poolRoute[1] = mainnetAaveWETHPool;

        uint256 aaveOutput = OracleConsulter.consult(
            poolRoute,
            tokenAddressRoute,
            14400,
            daiInput
        );

        assertApproxEqRel(
            aaveOutput,
            // where 10875160537248185 is ~= 1 AAVE/DAI on mainnet @ block 15895873
            FullMath.mulDiv(10875160537248185, _baseAmount, 1 ether),
            1e14
        );
    }
}
