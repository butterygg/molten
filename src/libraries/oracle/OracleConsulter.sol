// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

import "./OracleLibrary.sol";

library OracleConsulter {
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
        (int24 timeWeightedAverageTick, ) = OracleLibrary.consult(
            _params.pool,
            _params.period
        );

        twap = OracleLibrary.getQuoteAtTick(
            timeWeightedAverageTick,
            _params.baseAmount,
            _params.baseToken,
            _params.quoteToken
        );
    }
}
