// solhint-disable no-unused-vars
// solhint-disable no-empty-blocks
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {UniswapV3Adapter} from "../src/UniswapV3Adapter.sol";

contract OracleConsulterMock {
    uint256 public returnValue;

    constructor(uint256 _returnValue) {
        returnValue = _returnValue;
    }

    function consult(
        address,
        uint32,
        uint128,
        address,
        address
    ) external view returns (uint256) {
        return returnValue;
    }

    function consult(
        address[] calldata,
        address[] calldata,
        uint32,
        uint128
    ) external view returns (uint256) {
        return returnValue;
    }
}

contract QuerierImplem is UniswapV3Adapter {
    constructor(
        address uniswapV3OracleAddress,
        address[] memory _uniswapV3OraclePools,
        address[] memory _uniswapV3OracleTokens,
        uint32 _uniswapV3OraclePeriod
    )
        UniswapV3Adapter(
            uniswapV3OracleAddress,
            _uniswapV3OraclePools,
            _uniswapV3OracleTokens,
            _uniswapV3OraclePeriod
        )
    {}

    function query(uint128 baseAmount) public view returns (uint256) {
        return queryExchangeRate(baseAmount);
    }
}

contract UniswapV3AdapterTest is Test {
    OracleConsulterMock public o;
    QuerierImplem public q;

    function setUp() public {
        o = new OracleConsulterMock(20);
        address[] memory _one; // [XXX]
        address[] memory _two;
        q = new QuerierImplem(address(o), _one, _two, 1 days);
    }

    function testReturnsMockedConsultValue() public {
        assertEq(q.query(100 * 10**18), 20);
    }
}

contract UniswapV3AdapterFailTest is Test {
    OracleConsulterMock public o;
    QuerierImplem public q;

    function setUp() public {
        o = new OracleConsulterMock(uint256(type(uint128).max) + 1);
        address[] memory _one; // [XXX]
        address[] memory _two;
        q = new QuerierImplem(address(o), _one, _two, 1 days);
    }

    function testRevertsIfConsultNotUint128() public {
        vm.expectRevert();
        q.query(100 * 10 * 18);
    }
}
