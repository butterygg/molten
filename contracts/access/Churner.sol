// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Churner is AccessControl {
    bytes32 GOVERNOR = keccak256("MOLTEN_GOVERNOR");
    bytes32 DELEGATOR = keccak256("MOLTEN_DELEGATOR");

    address public governor;
    address public delegator;

    constructor(address _governor, address _delegator) {
        require(
            governor != address(0),
            "Churner#constructor: a governor needs to be assigned"
        );
        governor = _governor;
        delegator = _delegator;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNOR, _governor);
        _setupRole(DELEGATOR, _delegator);
    }

    function isGovernorOrDelegator(address account)
        private
        view
        returns (bool)
    {
        return (hasRole(GOVERNOR, account) || hasRole(DELEGATOR, account));
    }

    function setupGovernor(address newGovernor) public {
        require(
            isGovernorOrDelegator(msg.sender),
            "Churner#setupGovernor: not authorized"
        );
        governor = newGovernor;
    }

    function setupDelegator(address newDelegator) public {
        require(
            isGovernorOrDelegator(msg.sender),
            "Churner#setupDelegator: not authorized"
        );
        delegator = newDelegator;
    }
}
