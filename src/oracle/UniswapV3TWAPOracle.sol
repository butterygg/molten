// SPDX-License-Identifier: UNLICENSED
// solhint-disable no-empty-blocks
pragma solidity ^0.8.0;

import {OracleConsulter} from "./libraries/OracleConsulter.sol";

contract UniswapV3TWAPOracle {
    constructor() {}

    function getTWAP(
        address[] calldata pools,
        address[] calldata tokens,
        uint32 period,
        uint128 baseAmount
    ) public view returns (uint256) {
        if (pools.length == 1) {
            return
                OracleConsulter.consult(
                    pools[0],
                    period,
                    baseAmount,
                    tokens[0],
                    tokens[1]
                );
        }

        return OracleConsulter.consult(pools, tokens, period, baseAmount);
    }
}
