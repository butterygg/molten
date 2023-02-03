// SPDX-License-Identifier: UNLICENSED
// solhint-disable no-empty-blocks
pragma solidity ^0.8.17;

import {ERC20, ERC20Pausable, Pausable} from "openzeppelin/token/ERC20/extensions/ERC20Pausable.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract MTokenMock is ERC20Pausable, Owned {
    struct MintCall {
        address _sender;
        address to;
        uint256 amount;
    }
    MintCall public mintCalledWith;
    struct BurnCall {
        address _sender;
        address account;
        uint256 amount;
    }
    BurnCall public burnCalledWith;

    constructor(
        string memory name_,
        string memory symbol_,
        address _owner
    ) ERC20(name_, symbol_) Pausable() Owned(_owner) {}

    function pause() external onlyOwner {
        //
    }

    function unpause() external onlyOwner {
        //
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        mintCalledWith = MintCall({_sender:msg.sender, to: to, amount: amount});
    }

    function burn(address account, uint256 amount) public virtual onlyOwner {
        burnCalledWith = BurnCall({_sender:msg.sender, account: account, amount: amount});
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }
}

contract MTokenFailingMock is MTokenMock {
    bool private _fail = false;

    constructor(
        string memory name_,
        string memory symbol_,
        address _owner
    ) MTokenMock(name_, symbol_, _owner) {}

    function setFail() public {
        _fail = true;
    }
    function unsetFail() public {
        _fail = false;
    }

    function mint(address to, uint256 amount) public override onlyOwner {
        super.mint(to, amount);
        require(!_fail, "MTFM mint");
    }

    function burn(address account, uint256 amount) public override onlyOwner {
        super.burn(account, amount);
        require(!_fail, "MTFM burn");
    }
}
