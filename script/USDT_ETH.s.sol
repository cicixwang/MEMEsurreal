// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { BaseScript } from "./Base.s.sol";
import { USDT } from "test/mocks/USDT.t.sol";
import { IUniswapV2Router01 } from "../src/interfaces/IUniswapV2Router01.sol";

contract USDT_ETH is BaseScript {
    address uniswapV2Router;

    constructor() {
        if (block.chainid == 1) { } else if (block.chainid == 11_155_111) {
            uniswapV2Router = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
        }
    }

    function run() public broadcastByPrivateKey(deployerPrivateKey) {
        address deployer = vm.addr(deployerPrivateKey);
        USDT usdt;
        usdt = new USDT(); //USDT(0x710a714Eb1Bee6363523310554407CC70D6F2130);
        usdt.initialize("USDT", "USDT", 6);
        usdt.mint(deployer, 3500 * 10 ** 6);
        usdt.approve(uniswapV2Router, type(uint256).max);
        IUniswapV2Router01(uniswapV2Router).addLiquidityETH{ value: 0.1 ether }({
            token: address(usdt),
            amountTokenDesired: 350 * 10 ** 6,
            amountTokenMin: 0,
            amountETHMin: 0,
            to: deployer,
            deadline: block.timestamp+1000000
        });
    }
}
