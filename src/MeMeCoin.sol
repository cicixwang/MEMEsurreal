// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.25;

import { ERC20 } from "solady/src/tokens/ERC20.sol";

contract MeMeCoin is ERC20 {
    string private _name;
    string private _symbol;
    address public immutable agency;

    constructor(string memory name_, string memory symbol_, address agency_) {
        _name = name_;
        _symbol = symbol_;
        agency = agency_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function mint(address to, uint256 amount) external {
        require(agency == msg.sender, "Mint only by ERC7528Agency");
        _mint(to, amount);
    }
}
