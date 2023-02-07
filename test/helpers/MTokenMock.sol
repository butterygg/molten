// SPDX-License-Identifier: UNLICENSED
// solhint-disable no-empty-blocks
pragma solidity ^0.8.17;

import {ERC20, ERC20Pausable, Pausable} from "openzeppelin/token/ERC20/extensions/ERC20Pausable.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract MTokenMock is ERC20Pausable, Owned {
    bool public _mockFail = false;

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
        mintCalledWith = MintCall({
            _sender: msg.sender,
            to: to,
            amount: amount
        });
        require(!_mockFail, "MTFM mint");
    }

    function burn(address account, uint256 amount) public virtual onlyOwner {
        burnCalledWith = BurnCall({
            _sender: msg.sender,
            account: account,
            amount: amount
        });
        require(!_mockFail, "MTFM burn");
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function setFail() public {
        _mockFail = true;
    }

    function unsetFail() public {
        _mockFail = false;
    }
}
