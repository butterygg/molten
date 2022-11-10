// SPDX-License-Identifier: UNLICENSED
// solhint-disable no-unused-vars
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/oracle/UniswapV3TWAPOracle.sol";

contract OracleDeployer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        UniswapV3TWAPOracle oracle = new UniswapV3TWAPOracle();

        vm.stopBroadcast();
    }
}
