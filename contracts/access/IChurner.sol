// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IChurner {
    function getDao() external view returns (address);
    function getDelegator() external view returns (address);
    function grantRole(bytes32, address) external;
    function hasRole(bytes32, address) external view returns (bool);
    function isGovernorOrDelegator(address) external view returns (bool);
    function setupDelegator(address) external;
}
