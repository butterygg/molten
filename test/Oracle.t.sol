// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "uniswap-v3-core/interfaces/pool/IUniswapV3PoolDerivedState.sol";

import "../src/libraries/oracle/OracleConsulter.sol";

contract OracleLibraryTest is Test {
    uint256 public mainnetFork;

    function setUp() public {
        string memory mainnetRPCUrl = vm.envString("MAINNET_RPC_URL");
        mainnetFork = vm.createFork(mainnetRPCUrl, 15895873);
    }

    function testConsultWithForkTicks() public {
        vm.selectFork(mainnetFork);
        address forkedPoolAddress = 0x3597Ec44540b956B8F09DD3bF08e31c044e4533e; // GNOUSDT
        IUniswapV3PoolDerivedState forkedPool = IUniswapV3PoolDerivedState(
            forkedPoolAddress
        );

        uint32[] memory secsAgo = new uint32[](2);
        secsAgo[0] = 1440;
        secsAgo[1] = 0;
        (int56[] memory ticksCumulative, ) = forkedPool.observe(secsAgo);
        int256 tick0 = int256(ticksCumulative[0]);
        int256 tick1 = int256(ticksCumulative[1]);

        assertEq(tick0, -2125375051867);
        assertEq(tick1, -2125704181147);
    }

    function testConsultWithForkChained() public {
        vm.selectFork(mainnetFork);

        // ERC20s
        address forkedDai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address forkedWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address forkedAave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

        // Pools
        address forkedDaiWETHPool = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
        address forkedAaveWETHPool = 0x5aB53EE1d50eeF2C1DD3d5402789cd27bB52c1bB;

        uint128 oneDai = 1 ether;
        uint256 wethOutput = OracleConsulter.consultPriceAtTick(
            OracleConsulter.PriceConsultancyParams(
                forkedDaiWETHPool,
                14400,
                oneDai,
                forkedDai,
                forkedWETH
            )
        );
        uint256 aaveOutput = OracleConsulter.consultPriceAtTick(
            OracleConsulter.PriceConsultancyParams(
                forkedAaveWETHPool,
                14400,
                uint128(wethOutput),
                forkedWETH,
                forkedAave
            )
        );

        assertEq(aaveOutput, 10875160537248185); // ~0.0109 AAVE/DAI
    }
}
