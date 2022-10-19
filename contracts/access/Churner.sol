// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Churner is AccessControl {
    bytes32 constant DAO = keccak256("MOLTEN_DAO");
    bytes32 constant DELEGATOR = keccak256("MOLTEN_DELEGATOR");

    address public dao;
    address public delegator;

    constructor(address _dao, address _delegator) {
        require(
            dao != address(0),
            "Churner#constructor: a dao needs to be assigned"
        );
        dao = _dao;
        delegator = _delegator;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DAO, _dao);
        _setupRole(DELEGATOR, _delegator);
    }

    function isDaoOrDelegator(address account)
        public
        view
        returns (bool)
    {
        return (hasRole(DAO, account) || hasRole(DELEGATOR, account));
    }

    function setupDao(address newDao) public {
        require(
            isDaoOrDelegator(msg.sender),
            "Churner#setupDao: not authorized"
        );
        dao = newDao;
    }

    function setupDelegator(address newDelegator) public {
        require(
            isDaoOrDelegator(msg.sender),
            "Churner#setupDelegator: not authorized"
        );
        delegator = newDelegator;
    }

    function getDao() public view returns (address) {
        return dao;
    }

    function getDelegator() public view returns (address) {
        return delegator;
    }
}
