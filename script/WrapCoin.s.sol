// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { BaseScript } from "./Base.s.sol";
import { WrapCoin } from "test/mocks/WrapCoin.t.sol";
import { IUniswapV2Router01 } from "../src/interfaces/IUniswapV2Router01.sol";

contract WrapCoinScript is BaseScript {
    constructor() {
        if (block.chainid == 1) { } else if (block.chainid == 11_155_111) {
            
        }
    }

    function run() public broadcastByPrivateKey(deployerPrivateKey) {
        address deployer = vm.addr(deployerPrivateKey);
        WrapCoin wrapCoin;
        wrapCoin = new WrapCoin();
        wrapCoin.initialize("WrapCoin", "WRAP", 18);
        wrapCoin.mint(deployer, 1000 * 10 ** 18);
    }
}
