// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { CommonBase } from "forge-std/src/Base.sol";
import { StdCheatsSafe } from "forge-std/src/StdCheats.sol";
import { PoolManager } from "@uniswap/v4-core/src/PoolManager.sol";
import { IPositionManager } from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import { PositionManager } from "@uniswap/v4-periphery/src/PositionManager.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";
// import { PositionDescriptor } from "@uniswap/v4-periphery/src/PositionDescriptor.sol";
import { IPositionDescriptor } from "@uniswap/v4-periphery/src/interfaces/IPositionDescriptor.sol";
import { permit2At, wethAt } from "../../Constant.t.sol";

contract UniswapV4Deployer is CommonBase, StdCheatsSafe {
    PositionManager public posm;

    constructor() {
        PoolManager poolManager = new PoolManager();
        bytes memory code = vm.parseBytes(vm.readFile("test/deployedContract/permit2/code.txt"));
        vm.etch(permit2At, code);
        // IPositionDescriptor positionDescriptor = new PositionDescriptor(poolManager, wethAt, "ETH");
        IPositionDescriptor positionDescriptor = IPositionDescriptor(
            deployCode("out/PositionDescriptor.sol/PositionDescriptor.json", abi.encode(poolManager, wethAt, "ETH"))
        );
        posm = new PositionManager{ salt: hex"03" }(
            poolManager, IAllowanceTransfer(permit2At), 100_000, positionDescriptor
        );
    }
}
