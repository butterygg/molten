// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";

contract UniV2OracleLib {
    using FixedPoint for *;

    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    address public pair;
    uint256 public immutable windowSize;
    uint8 public immutable granularity;
    uint256 public immutable periodSize;

    Observation[] public pairObservations;

    constructor(
        address _pair,
        uint256 _windowSize,
        uint8 _granularity
    ) {
        require(
            _granularity > 1,
            "UniV2OracleLib: insufficient granularity given"
        );
        require(
            (periodSize = _windowSize / _granularity) * _granularity ==
                _windowSize,
            "UniV2OracleLib: a given window needs to evenly divisible"
        );

        pair = _pair;
        windowSize = _windowSize;
        granularity = _granularity;
    }

    function observationIndexOf(uint256 timestamp) returns (uint8 index) {
        uint256 epochPeriod = timestamp / periodSize;
        return uint8(epochPeriod % granularity);
    }

    function getFirstObervationInWindow()
        returns (Observation storage firstObservation)
    {
        uint8 currentObservationIndex = observationIndexOf(block.timestamp);
        unchecked {
            uint8 firstObservationIndex = (currentObservationIndex + 1) %
                granularity;
        }

        firstObservation = pairObservations[firstObservationIndex];
    }

    function update() external {
        for (uint256 i = pairObservations.length; i < granularity; i++) {
            pairObservations.push();
        }
        uint8 observationIndex = observationIndexOf(block.timestamp);

        Observation storage observation = pairObservations[observationIndex];

        uint256 timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            (
                uint256 price0Cumulative,
                uint256 price1Cumulative,

            ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            observation.timestamp = block.timestamp;
            observation.price0Cumulative = price0Cumulative;
            observation.price1Cumulative = price1Cumulative;
        }
    }

    function computeAmountOut(
        uint256 priceCumulatitiveStart,
        uint256 priceCumulatitiveEnd,
        uint256 timeElapsed,
        uint265 amountIn
    ) private pure returns (uint256 amountOut) {
        unchecked {
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224(
                    (priceCumulatitiveEnd - priceCumulatitiveStart) /
                        timeElapsed
                )
            );
        }

        amountOut = priceAverage.mul(amountIn).decode144();
    }

    function consult(address tokenIn, uint256 amountIn) returns (uint256 amountOut) {
        Observation storage observationStart = getFirstObervationInWindow();

        uint256 timeElapsed = block.timestamp - observationStart.timestamp;
        require(timeElapsed <= windowSize, "UniV2OracleLib: too soon to calculate twap");
        require(timeElapsed >= windowSize - periodSize * 2, "UniV2OracleLib: unexpected time elapsed");

        (uint256 price0Cumulative, uint256 price0Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        address token0 = IUniswapV2Pair(pair).token0();

        if (token0 == tokenIn) {
            return computeAmountOut(observationStart.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(observationStart.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }
}
