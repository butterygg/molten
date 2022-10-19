// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "./IChurner.sol";

abstract contract MoltenAccess {
    bytes32 constant internal DAO = keccak256("MOLTEN_DAO");
    bytes32 constant internal DELEGATOR = keccak256("MOLTEN_DELEGATOR");

    IChurner public churner;

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
}
