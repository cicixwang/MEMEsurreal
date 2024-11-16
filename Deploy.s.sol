// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { BaseScript } from "./Base.s.sol";
import { Agent } from "src/Agent.sol";
import { WrapMeMeLaunch } from "src/WrapMeMeLaunch.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    address dotAgency;
    address factory;
    address wrapCoin;
    address posm;
    address usdt;
    address safeVault;

    constructor() {
        if (block.chainid == 1) { } else if (block.chainid == 11_155_111) {
            dotAgency = 0x6c0f185803a21e7366569c93799782Cc4Ed26869;
            factory = 0x1e5e8eAA1507097A88ee342DF5CC754A8AbEc54e;
            posm = 0x1B1C77B606d13b09C84d1c7394B96b147bC03147;
            wrapCoin = 0x987e855776C03A4682639eEb14e65b3089EE6310;
            usdt = 0x37ccE8133af1B48F6daEffa2F33b386dD6Dedc59;
            safeVault = 0xde454c2190448340Edbc6DEE1146E11159DE65E5;
        } else if (block.chainid == 84532) {
            dotAgency = 0xc39EEE176D676292DD2AF620c44F6628548C1f34;
            factory = 0x33A7cCbCD9630E37356d19102083bf3f13f4cC59;
           wrapCoin = 0x548A7404C1089c2B0b0b8dfe25784446c7d30B22;
                       usdt = 0x37ccE8133af1B48F6daEffa2F33b386dD6Dedc59;
            posm = 0xcDbe7b1ed817eF0005ECe6a3e576fbAE2EA5EAFE;

            safeVault = 0xde454c2190448340Edbc6DEE1146E11159DE65E5;
        }
    }

    function run() public broadcastByPrivateKey(deployerPrivateKey) {
        new Agent(dotAgency, factory);
        new WrapMeMeLaunch(dotAgency, posm, wrapCoin, address(usdt), safeVault);
    }
}
