// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

import "./OracleLibrary.sol";

library OracleConsulter {
    function consult(
        address pool,
        uint32 period,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) external view returns (uint256 twap) {
        (int24 timeWeightedAverageTick, ) = OracleLibrary.consult(pool, period);

        twap = OracleLibrary.getQuoteAtTick(
            timeWeightedAverageTick,
            baseAmount,
            baseToken,
            quoteToken
        );
    }

    function consult(
        address[] calldata pools,
        address[] calldata tokens,
        uint32 period,
        uint128 baseAmount
    ) external view returns (uint256) {
        uint256 poolsLength = pools.length;
        int24[] memory tickRoute = new int24[](poolsLength);

        for (uint256 i = 0; i < poolsLength; i++) {
            (tickRoute[i], ) = OracleLibrary.consult(pools[i], period);
        }
        int256 chainedMeanTick = OracleLibrary.getChainedPrice(
            tokens,
            tickRoute
        );

        require(
            chainedMeanTick <= type(int24).max,
            "Oracle Consulter: tick overflow"
        );

        return
            OracleLibrary.getQuoteAtTick(
                int24(chainedMeanTick),
                baseAmount,
                tokens[0],
                tokens[tokens.length - 1]
            );
    }
}
