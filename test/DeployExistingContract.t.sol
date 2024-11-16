// SPDX-License-Identifier: UNLICENSED
import { CommonBase } from "forge-std/src/Base.sol";
import { factoryAt, uniswapV2RouterAt, wethAt, uniFactoryAt, permit2At } from "./Constant.t.sol";

pragma solidity >=0.8.25;

contract DeployExistingContract is CommonBase {
    constructor() {
        factory();
        uniswapV2Router();
        weth();
        uniFactory();
        permit2();
    }

    function factory() internal {
        bytes memory code = vm.parseBytes(vm.readFile("test/deployedContract/factory/code.txt"));
        vm.etch(factoryAt, code);
    }

    function uniswapV2Router() internal {
        bytes memory code = vm.parseBytes(vm.readFile("test/deployedContract/uniswapV2Router/code.txt"));
        vm.etch(uniswapV2RouterAt, code);
    }

    function weth() internal {
        bytes memory code = vm.parseBytes(vm.readFile("test/deployedContract/WETH/code.txt"));
        vm.etch(wethAt, code);
    }

    function uniFactory() internal {
        bytes memory code = vm.parseBytes(vm.readFile("test/deployedContract/uniFactory/code.txt"));
        vm.etch(uniFactoryAt, code);
    }

    function permit2() internal {
        bytes memory code = vm.parseBytes(vm.readFile("test/deployedContract/permit2/code.txt"));
        vm.etch(permit2At, code);
    }
}
