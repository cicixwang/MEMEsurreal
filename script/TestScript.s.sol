// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { BaseScript } from "./Base.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Agent } from "src/Agent.sol";
import { WrapMeMeLaunch } from "src/WrapMeMeLaunch.sol";
import { IUniswapV2Router01 } from "../src/interfaces/IUniswapV2Router01.sol";
import { IERC7527Factory, AgencySettings, AppSettings } from "test/deployedContract/factory/IERC7527Factory.sol";
import { Asset } from "src/interfaces/IERC7527Agency.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { WrapCoin } from "test/mocks/WrapCoin.t.sol";

interface ICall {
    // dotAgency
    function mint(string calldata name, uint256 priceNonce) external payable returns (uint256);
}
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract TestScript is BaseScript {
    address dotAgency;
    address factory;
    address wrapCoin;
    address posm;
    address usdt;
    address uniswapV2Router;
    address safeVault;

    address agencyImplementation;
    address appImplementation;

    constructor() {
        if (block.chainid == 1) { } else if (block.chainid == 11_155_111) {
            dotAgency = 0x6c0f185803a21e7366569c93799782Cc4Ed26869;
            factory = 0x1e5e8eAA1507097A88ee342DF5CC754A8AbEc54e;
            posm = 0x1B1C77B606d13b09C84d1c7394B96b147bC03147;
            wrapCoin = 0x26A7Cf1326a8daA6EC04DdC07304994049E93fCd;
            usdt = 0x37ccE8133af1B48F6daEffa2F33b386dD6Dedc59;
            uniswapV2Router = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
            safeVault = 0x623727C7b3fe060C41C12CD98258809EBC488C1C;
            agencyImplementation = 0x33A7cCbCD9630E37356d19102083bf3f13f4cC59;
            // 0x1d0945f5443Aa69Ca1ac891857032eDB38609Ba8
            appImplementation = 0x5a27330c340bd56580c7933fc90295cc25D8301b;
            // 0x965ffAf8c10C53539735C512DF243a9f09eF150a
        } else if (block.chainid == 84532) {
            dotAgency = 0xc39EEE176D676292DD2AF620c44F6628548C1f34;
            factory = 0x33A7cCbCD9630E37356d19102083bf3f13f4cC59;
            wrapCoin = 0x548A7404C1089c2B0b0b8dfe25784446c7d30B22;
            usdt = 0x37ccE8133af1B48F6daEffa2F33b386dD6Dedc59;
            safeVault = 0xde454c2190448340Edbc6DEE1146E11159DE65E5;
            agencyImplementation = 0xc80a055b6f36a0cA0Fb0559EeAc3ed89346AD963;
            appImplementation = 0x5c40D1265BDeE0095F35A49613634Dc4CFE8DcC0;
        }
    }

    /*
    * Mint wrapCoin to deployer for next test
    * Approve dotAgency to spend wrapCoin
    * Mint dotAgency
    * Deploy agencyInstance and appInstance
    * Approve agencyInstance to spend wrapCoin
    * Wrap
    */
    function run() public broadcastByPrivateKey(deployerPrivateKey) {
        address deployer = vm.addr(deployerPrivateKey);
        WrapCoin(wrapCoin).mint(deployer, 1000 * 10 ** 18); // Mint wrapCoin to deployer for next test
        IERC20(wrapCoin).approve(dotAgency, type(uint256).max);
        uint256 tokenIdOfDotAgency = ICall(dotAgency).mint("hack", 10 ether); // The tokenId of dotAgency is needed for _deployERC7527
        address agencyInstance = _deployERC7527(tokenIdOfDotAgency, agencyImplementation, appImplementation); // Record agencyInstance for next test
        // address agencyInstance = 0xfAa8e5B0Ef93dF841B37807E13Fe77Ff54986Ac2;
        // IERC20(wrapCoin).approve(address(agencyInstance), 1000 ether);
        // WrapMeMeLaunch wrapMeMeLaunchInstance = WrapMeMeLaunch(payable(agencyInstance));
        // wrapMeMeLaunchInstance.unwrap(deployer, 1, abi.encode(5000e18, ""));
    }

    function _deployERC7527(
        uint256 tokenIdOfDotAgency,
        address agencyImplementation_,
        address appImplementation_
    )
        internal
        returns (address agencyInstance)
    {
        agencyInstance = IERC7527Factory(factory).deployERC7527(
            AgencySettings({
                implementation: payable(agencyImplementation_),
                asset: Asset(
                    address(0), // currency is ETH if address(0)
                    0,
                    address(0), // recipient
                    0,
                    0
                ),
                immutableData: "",
                initData: ""
            }),
            AppSettings({
                implementation: appImplementation_,
                immutableData: abi.encode(uint256(20), tokenIdOfDotAgency),
                initData: ""
            }),
            abi.encode(tokenIdOfDotAgency) // In this contract, it is `abi.encode(tokenId)`.
        );
    }

    function _latestWrap(WrapMeMeLaunch wrapMeMeLaunchInstance) internal {
        for (uint256 i = 0; i < 255; i++) {
            ICall(dotAgency).mint{ value: 2 ether }(string(abi.encodePacked("forwrapcoin", Strings.toString(i))), 0);
        }
        _wraps(200, wrapMeMeLaunchInstance);
    }

    function _wraps(uint256 times, WrapMeMeLaunch wrapMeMeLaunchInstance) internal {
        for (uint256 i = 0; i < times; i++) {
            wrapMeMeLaunchInstance.wrap(address(this), abi.encode(5000e18, ""));
            vm.roll(block.number + 1000);
        }
    }
}
