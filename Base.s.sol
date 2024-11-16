// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/src/Script.sol";

abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    string internal mnemonic;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    uint256 internal deployerPrivateKey;

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $ETH_FROM is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    ///
    /// The use case for $ETH_FROM is to specify the broadcaster key and its address via the command line.
    constructor() {
        string memory prefix = "";
        if (block.chainid == 31_337) {
            prefix = "LOCAL_";
        } else if (block.chainid == 5) {
            prefix = "GOERLI_";
        } else if (block.chainid == 11_155_111) {
            prefix = "SEPOLIA_";
        } else if (block.chainid == 84532) {
            prefix = "BASE_";
        }
        address from = vm.envOr({ name: "ETH_FROM", defaultValue: address(0) });
        if (from != address(0)) {
            broadcaster = from;
        } else {
            deployerPrivateKey = vm.envOr({ name: string.concat(prefix, "DEPLOYER_KEY"), defaultValue: uint256(0) });
            require(deployerPrivateKey != 0, "No private key provided");
            // if(privateKey != 0){
            //     broadcaster = vm.addr(privateKey);
            // } else {
            //     mnemonic = vm.envOr({ name: string.concat(prefix, "MNEMONIC") , defaultValue: TEST_MNEMONIC });
            //     (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
            // }
        }
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    modifier broadcastByPrivateKey(uint256 privateKey) {
        vm.startBroadcast(privateKey);
        _;
        vm.stopBroadcast();
    }
}
