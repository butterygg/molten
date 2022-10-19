// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract Mutex {
    enum MUTEX_IS {
        NOT_IMPLEMENTED,
        NOT_LOCKED,
        LOCKED
    }

    uint8 internal lockStatus;

    modifier isNotLocked() {
        require(lockStatus != uint8(MUTEX_IS.LOCKED));
        lockStatus = 2;
        _;
        lockStatus = 1;
    }
}
