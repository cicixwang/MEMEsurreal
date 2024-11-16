// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { MockERC20 } from "forge-std/src/mocks/MockERC20.sol";

contract WrapCoin is MockERC20 {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
