// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";
import { wethAt, uniFactoryAt, uniswapV2RouterAt, dotAgencyAt, factoryAt } from "./Constant.t.sol";
import { WrapMeMeLaunch } from "../src/WrapMeMeLaunch.sol";
import { Agent } from "../src/Agent.sol";
import { DeployExistingContract } from "./DeployExistingContract.t.sol";
import { IDotAgency } from "./deployedContract/dotAgency/IDotAgency.sol";
import { IERC7527Factory, AgencySettings, AppSettings } from "./deployedContract/factory/IERC7527Factory.sol";
import { IUniswapV2Router01 } from "../src/interfaces/IUniswapV2Router01.sol";
import { Asset } from "src/interfaces/IERC7527Agency.sol";
import { PositionManager } from "@uniswap/v4-periphery/src/PositionManager.sol";
import { Users } from "./type.sol";
import { USDT } from "./mocks/USDT.t.sol";
import { WrapCoin } from "./mocks/WrapCoin.t.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { UniswapV4Deployer } from "./deployedContract/uniswapV4/uniswapV4.sol";
import { PoolSwapTest } from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { TickMath } from "@uniswap/v4-core/src/libraries/TickMath.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";
import { IHooks } from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import { sqrt } from "@prb/math/src/Common.sol";
import { PositionManager } from "@uniswap/v4-periphery/src/PositionManager.sol";
import { PoolInitializer } from "@uniswap/v4-periphery/src/base/PoolInitializer.sol";
import { LiquidityAmounts } from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";

contract WrapMeMeLaunchTest is Test {
    PositionManager posm;
    WrapMeMeLaunch wrapMeMeLaunch;
    WrapMeMeLaunch wrapMeMeLaunchInstance;
    Agent agent;
    IDotAgency dotAgency;
    Users users;
    address internal wrapCoinAt;
    USDT usdt;
    WrapCoin wrapCoin;
    receive() external payable { }

    constructor() {
        posm = new UniswapV4Deployer().posm();
        new DeployExistingContract();
    }

    function setUp() public {
        _createUsers();
        wrapCoin = new WrapCoin();
        wrapCoin.initialize("WrapCoin", "WrapCoin", 18);
        wrapCoin.mint(address(this), 2000 ether);
        wrapCoin.approve(dotAgencyAt, type(uint256).max);
        wrapCoinAt = address(wrapCoin);
        vm.label(wrapCoinAt, "wrapCoin");

        deployCodeTo(
            "test/deployedContract/dotAgency/DotAgency.json",
            abi.encode(
                ".agency",
                ".agency",
                address(wrapCoin),
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            ),
            dotAgencyAt
        );
        dotAgency = IDotAgency(dotAgencyAt);
        uint256 tokenIdOfDotAgency = _mintDotAgency(address(this), "test");
        _addLiquidity();
        wrapMeMeLaunch = new WrapMeMeLaunch(
            dotAgencyAt,
            address(posm),
            wrapCoinAt,
            address(usdt),
            _createUser("transactionFee")
        );
        agent = new Agent(dotAgencyAt, factoryAt);
        wrapMeMeLaunchInstance =
            WrapMeMeLaunch(payable(_deployERC7527(tokenIdOfDotAgency, address(wrapMeMeLaunch), address(agent))));
    }

    function testWrap() public {
      USDT(wrapCoinAt).approve(address(wrapMeMeLaunchInstance), type(uint256).max);
        _wraps(1);
    }

    function testLaunch() public {
        _latestWrap();
    }

    function testClaimMemeCoin() public {
        _latestWrap();
        wrapMeMeLaunchInstance.claimMemeCoin(1);
    }

    function testClaimLPFee() public {
        _claimLPFee();
        (uint256 fee0, uint256 fee1) = wrapMeMeLaunchInstance.claimLPFee();
        console2.log("fee0", fee0);
        console2.log("fee1", fee1);
    }

    function testClaimFee() public {
        _claimLPFee();
        wrapMeMeLaunchInstance.claimLPFee();

        (uint256 fee0, uint256 fee1) = wrapMeMeLaunchInstance.claimFee(1, users.lpFeeReceiver);
        console2.log("fee0", fee0);
        console2.log("fee1", fee1);
    }

    function _claimLPFee() internal {
        _latestWrap();
        vm.prank(users.swaper);
        address token0 = address(wrapMeMeLaunchInstance.memeCoin());
        address token1 = wrapCoinAt;
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }
        _swap(token0, token1, -3e18);
        vm.stopPrank();
    }

    function _swap(address token0, address token1, int256 amount) internal {
        PoolSwapTest swapRouter = new PoolSwapTest(posm.poolManager());

        // slippage tolerance to allow for unlimited price impact
        uint160 MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
        uint160 MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 10_000,
            tickSpacing: 200,
            hooks: IHooks(address(0))
        });

        // approve tokens to the swap router
        USDT(token0).approve(address(swapRouter), type(uint256).max);
        USDT(token1).approve(address(swapRouter), type(uint256).max);

        bool zeroForOne = true;
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amount,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT // unlimited impact
         });

        // in v4, users have the option to receieve native ERC20s or wrapped ERC1155 tokens
        // here, we'll take the ERC20s
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({ takeClaims: false, settleUsingBurn: false });

        bytes memory hookData = new bytes(0); // no hook data on the hookless pool
        swapRouter.swap(pool, params, testSettings, hookData);
    }

    function _mintDotAgency(address to, string memory name) internal returns (uint256 tokenId) {
        vm.prank(to);
        // TODO:
        // uint256 commitId = dotAgency.commit();
        vm.roll(block.number + 10);
        vm.warp(block.timestamp + 10 hours);
        tokenId = dotAgency.mint(name, type(uint256).max);
    }

    function _addLiquidity() internal {
        usdt = new USDT();
        usdt.initialize("USDT", "USDT", 6);
        usdt.mint(address(this), 1000 * 10 ** 6);

        address currency0 = wrapCoinAt;
        address currency1 = address(usdt);
        uint256 amount0Max = 1000 ether;
        uint256 amount1Max = 1000 * 10 ** 6;
        
        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
            (amount0Max, amount1Max) = (amount1Max, amount0Max);
        }

        int24 tickSpacing = 200;
        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(currency0),
            currency1: Currency.wrap(currency1),
            fee: 10_000,
            tickSpacing: tickSpacing,
            hooks: IHooks(address(0))
        });

        bytes[] memory params = new bytes[](2);
        uint160 startingPrice = uint160(sqrt(amount1Max * 2 ** 96 / amount0Max) * 2 ** 48); // is expressed as
            // sqrtPriceX96: floor(sqrt(token1 / token0) * 2^96)
        params[0] = abi.encodeWithSelector(PoolInitializer.initializePool.selector, pool, startingPrice);

        bytes[] memory mintParams = new bytes[](2);

        uint256 liquidityToAdd = LiquidityAmounts.getLiquidityForAmounts({
            sqrtPriceX96: startingPrice,
            sqrtPriceAX96: TickMath.getSqrtPriceAtTick(TickMath.minUsableTick(tickSpacing)),
            sqrtPriceBX96: TickMath.getSqrtPriceAtTick(TickMath.maxUsableTick(tickSpacing)),
            amount0: amount0Max,
            amount1: amount1Max
        });
        mintParams[0] = abi.encode(
            pool,
            TickMath.minUsableTick(tickSpacing),
            TickMath.maxUsableTick(tickSpacing),
            liquidityToAdd,
            amount0Max,
            amount1Max,
            address(this),
            ""
        );
        mintParams[1] = abi.encode(pool.currency0, pool.currency1);

        bytes memory actions = new bytes(2);
        actions[0] = bytes1(uint8(Actions.MINT_POSITION));
        actions[1] = bytes1(uint8(Actions.SETTLE_PAIR));
        uint256 deadline = block.timestamp + 60;
        params[1] = abi.encodeWithSelector(
            PositionManager.modifyLiquidities.selector, abi.encode(actions, mintParams), deadline
        );

        USDT(currency0).approve(address(posm.permit2()), amount0Max);
        USDT(currency1).approve(address(posm.permit2()), amount1Max);
        posm.permit2().approve(currency0, address(posm), type(uint160).max, type(uint48).max);
        posm.permit2().approve(currency1, address(posm), type(uint160).max, type(uint48).max);
        PositionManager(posm).multicall(params);
    }

    function _deployERC7527(
        uint256 tokenIdOfDotAgency,
        address agencyImplementation,
        address appImplementation
    )
        internal
        returns (address agencyInstance)
    {
        agencyInstance = IERC7527Factory(factoryAt).deployERC7527(
            AgencySettings({
                implementation: payable(agencyImplementation),
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
                implementation: appImplementation,
                immutableData: abi.encode(uint256(20), tokenIdOfDotAgency),
                initData: ""
            }),
            abi.encode(tokenIdOfDotAgency) // In this contract, it is `abi.encode(tokenId)`.
        );
    }

    function _createUsers() internal {
        users.testOwner = _createUser("testOwner");
        users.swaper = _createUser("swaper");
        users.lpFeeReceiver = _createUser("lpFeeReceiver");
    }

    function _createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        return user;
    }

    function _latestWrap() internal {
        for (uint256 i = 0; i < 255; i++) {
            _mintDotAgency(address(this), string(abi.encodePacked("forwrapcoin", Strings.toString(i))));
        }
        USDT(wrapCoinAt).approve(address(wrapMeMeLaunchInstance), type(uint256).max);
        _wraps(3);
    }

    function _wraps(uint256 times) internal {
        for (uint256 i = 0; i < times; i++) {
            wrapMeMeLaunchInstance.wrap(address(this), abi.encode(5000e18, ""));
            vm.roll(block.number + 1000);
        }
    }
}
