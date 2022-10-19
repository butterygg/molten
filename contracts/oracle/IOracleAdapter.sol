// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOracleAdapter {
    function getOracleImplementation() external view returns (uint8);
    function consult(uint256) external view returns (uint256);
    function update() external;
}
