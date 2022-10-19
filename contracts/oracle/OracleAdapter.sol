// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../access/IChurner.sol";
import "./v2/IUniV2OracleConsulter.sol";
import "./v2/UniV2OracleConsulter.sol";
import "./v3/UniV3OracleConsulter.sol";

contract OracleAdapter {
    event UniV2OracleDeployed(address);
    event OracleImplementationSwitch(uint8);

    enum OracleSwitch {
        NO_IMPLEMENTATION,
        V2,
        V3
    }
    uint8 public oracleImplementation;

    address public daoToken;
    IChurner public churner;
    IUniV2OracleConsulter public uniV2Oracle;

    address public v3Pool;
    address public v3QuoteToken;
    uint32 public v3Period;

    modifier onlyRole(bytes32 role) {
        address account = msg.sender;
        if (!churner.hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Churner: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
        _;
    }

    constructor(
        address _churnerAddress,
        address _daoToken,
        uint8 _init_oracle_implementation
    ) {
        require(
            _daoToken != address(0),
            "OracleAdapter: daoToken must be defined"
        );
        churner = IChurner(_churnerAddress);
        oracleImplementation = _init_oracle_implementation;
        daoToken = _daoToken;
    }

    function setupV2Oracle(
        address _pair,
        uint256 _windowSize,
        uint8 _granularity
    ) external onlyRole(0x00) {
        UniV2OracleConsulter _uniV2Oracle = new UniV2OracleConsulter(
            _pair,
            _windowSize,
            _granularity
        );

        address v2OracleAddress = address(_uniV2Oracle);
        uniV2Oracle = IUniV2OracleConsulter(v2OracleAddress);
        emit UniV2OracleDeployed(v2OracleAddress);
        uniV2Oracle.update();
    }

    function setupV3Oracle(
        address _pool,
        address _quoteToken,
        uint32 _period
    ) external onlyRole(0x00) {
        v3Pool = _pool;
        v3QuoteToken = _quoteToken;
        v3Period = _period;
    }

    function implementationSwitch(uint8 implementationEnum)
        external
        onlyRole(0x00)
    {
        require(
            implementationEnum < 3 && implementationEnum != 0,
            "OracleAdapter: implementation must be in range [1, 2]"
        );
        oracleImplementation = implementationEnum;
        emit OracleImplementationSwitch(implementationEnum);
    }

    function getOracleImplementation() external view returns (uint8) {
        return oracleImplementation;
    }

    function consult(uint256 amount) external view returns (uint256) {
        require(
            oracleImplementation != 0,
            "OracleAdapter: an implementation must be switched on"
        );
        if (oracleImplementation == uint8(OracleSwitch.V2)) {
            return (consult_v2(amount));
        } else {
            return (consult_v3(uint128(amount)));
        }
    }

    function update() external {
        if (oracleImplementation == 1) {
            return;
        }

        uniV2Oracle.update();
    }

    function consult_v2(uint256 amount) private view returns (uint256) {
        require(
            address(uniV2Oracle) != address(0),
            "Oracle Adapter: Uni V2 Oracle undefined"
        );

        return (uniV2Oracle.consult(daoToken, amount));
    }

    function consult_v3(uint128 amount) private view returns (uint256) {
        return
            UniV3OracleConsulter.consultPriceAtTick(
                UniV3OracleConsulter.PriceConsultancyParams(
                    v3Pool,
                    v3Period,
                    amount,
                    daoToken,
                    v3QuoteToken
                )
            );
    }
}
