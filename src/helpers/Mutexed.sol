// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// [TODO] Tests.

abstract contract Mutexed {
    enum MutexIs {
        NOT_IMPLEMENTED,
        NOT_LOCKED,
        LOCKED
    }

    uint8 internal lockStatus;

    modifier isNotLocked() {
        require(lockStatus != uint8(MutexIs.LOCKED), "Mutex: locked");
        lockStatus = 2;
        _;
        lockStatus = 1;
    }
}
