// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UniV3OracleLib.sol";

library UniV3OracleConsulter {

    struct PriceConsultancyParams {
        address pool;
        uint32 period;
        uint128 baseAmount;
        address baseToken;
        address quoteToken;
    }

    function consultPriceAtTick(PriceConsultancyParams calldata _params)
        external
        view
        returns (uint256 twap)
    {
        (int24 timeWeightedAverageTick, ) = UniV3OracleLib.consult(
            _params.pool,
            _params.period
        );

        twap = UniV3OracleLib.getQuoteAtTick(
            timeWeightedAverageTick,
            _params.baseAmount,
            _params.baseToken,
            _params.quoteToken
        );
    }
}
