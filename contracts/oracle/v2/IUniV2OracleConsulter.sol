// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniV2OracleConsulter {
    function observationIndexOf(uint256 timestamp) external view returns (uint8);
    function getFirstObervationInWindow() external;
    function update() external;
    function consult(address, uint256) external view returns (uint256);
}
