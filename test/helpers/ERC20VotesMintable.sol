// SPDX-License-Identifier: UNLICENSED
// solhint-disable no-empty-blocks
pragma solidity ^0.8.17;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Votes, ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";

contract ERC20VotesMintable is ERC20Votes {
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC20Permit("daoToken")
    {}

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }
}

contract ERC20VotesMintableMock is ERC20Votes {
    struct TransferFromCall {
        address from;
        address to;
        uint256 amount;
    }
    TransferFromCall public transferFromCalledWith;

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC20Permit("daoToken")
    {}

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        transferFromCalledWith = TransferFromCall({
            from: from,
            to: to,
            amount: amount
        });
        return true;
    }
}

contract ERC20VotesMintableFailedMock is ERC20Votes {
    bool private _fail = false;

    struct TransferFromCall {
        address from;
        address to;
        uint256 amount;
    }
    TransferFromCall public transferFromCalledWith;

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC20Permit("daoToken")
    {}

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        transferFromCalledWith = TransferFromCall({
            from: from,
            to: to,
            amount: amount
        });
        require(!_fail, "ERC20VMFM transferFrom");
        return true;
    }

    function setFail() public {
        _fail = true;
    }

    function unsetFail() public {
        _fail = false;
    }
}
