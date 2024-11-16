// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/strings.sol";
import { IERC7527Agency, Asset } from "./interfaces/IERC7527Agency.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC7527App } from "./interfaces/IERC7527App.sol";
import { FixedPointMathLib } from "solady/src/utils/FixedPointMathLib.sol";
import { IANS } from "ANS@1.0.0/src/IANS.sol";
import { MeMeCoin } from "./MeMeCoin.sol";
import { PositionManager } from "@uniswap/v4-periphery/src/PositionManager.sol";
import { PoolInitializer } from "@uniswap/v4-periphery/src/base/PoolInitializer.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";
import { IHooks } from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import { TickMath } from "@uniswap/v4-core/src/libraries/TickMath.sol";
import { LiquidityAmounts } from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import { sqrt } from "@prb/math/src/Common.sol";

contract WrapMeMeLaunch is ReentrancyGuard, IERC7527Agency {
    using FixedPointMathLib for int256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    /// storage
    uint256 constant MAX_SUPPLY = 3;
    uint256 constant MEME_COIN_EVERY_WRAPER = 300_000_000 ether / MAX_SUPPLY;

    address public immutable dotAgency;
    PositionManager public immutable posm;

    // The address of Wrap Coin
    address public immutable wrapCoin;
    address public immutable usdt;
    mapping(uint256 tokenId => bool claimed) public memeCoinClaimed;

    uint256 public feeCount;
    MeMeCoin public memeCoin;

    uint256 private _lastPrice;
    uint256 private _lastMintTime;
    uint256 private _basePremium;
    uint256[] private autionPriceList;
    uint256 public fee0Average;
    uint256 public fee1Average;
    address public immutable vault;
    uint256 public tokenIdOfLiquidity;
    mapping(uint256 tokenId => uint256 fee0Debt) public fee0Debt;
    mapping(uint256 tokenId => uint256 fee1Debt) public fee1Debt;

    error WrapMeMeLaunchNotOwnerAndNotApproved(address);
    error WrapMeMeLaunchExceededSlippagePrice(uint256 required, uint256 available);
    error WrapMeMeLaunchConstructed();

    constructor(
        address dotAgency_,
        address posm_,
        address wrapCoin_,
        address usdt_,
        address vault_
    ) {
        dotAgency = dotAgency_;
        posm = PositionManager(posm_);
        wrapCoin = wrapCoin_;
        usdt = usdt_;
        vault = vault_;
    }

    receive() external payable { }

    function iconstructor() external override {
        if (autionPriceList.length != 0) revert WrapMeMeLaunchConstructed();
        // address[] memory path = new address[](2);
        // path[0] = wrapCoin;
        // path[1] = usdt;
        // _basePremium = uniswapV2Router.getAmountsIn(10e6, path)[0];
        _basePremium = 10 ether;
        (, Asset memory _asset,) = getStrategy();

        autionPriceList.push(uint128(_asset.basePremium));

        bytes32 node = IANS(dotAgency).getNode(tokenIdOfDotAgency());
        bytes memory fullname = IANS(dotAgency).getName(node);
        bytes memory namelabel = new bytes(fullname.length - 7);
        assembly {
            mstore(add(namelabel, 0x20), mload(add(fullname, 0x20)))
        }
        memeCoin = new MeMeCoin(string(bytes.concat(namelabel, bytes("token"))), string(namelabel), address(this));
    }

    function wrap(address to, bytes calldata data) external payable override nonReentrant returns (uint256 tokenId) {
        (uint256 slippagePrice,) = abi.decode(data, (uint256, bytes));
        (address appInstance, Asset memory _asset,) = getStrategy();

        (uint256 swap, uint256 mintFee) = getWrapOracle(abi.encode(""));

        uint256 totalCost = swap + mintFee;
        feeCount += mintFee;

        if (totalCost > slippagePrice) revert WrapMeMeLaunchExceededSlippagePrice(totalCost, slippagePrice);
        IERC20 currencyERC20 = IERC20(_asset.currency);
        currencyERC20.safeTransferFrom(msg.sender, address(this), totalCost);

        tokenId = IERC7527App(appInstance).mint(to, "");

        _lastMintTime = block.timestamp;
        _lastPrice = swap;
        autionPriceList.push(_lastPrice);

        emit Wrap(to, tokenId, swap, mintFee);
    }

    function unwrap(address to, uint256 tokenId, bytes calldata data) external payable override nonReentrant {
        (address appInstance, Asset memory _asset,) = getStrategy();
        if (!_isApprovedOrOwner(appInstance, msg.sender, tokenId)) {
            revert WrapMeMeLaunchNotOwnerAndNotApproved(msg.sender);
        }
        IERC7527App(appInstance).burn(tokenId, data);
        (uint256 swap, uint256 burnFee) = getUnwrapOracle(abi.encode(""));

        autionPriceList.pop();

        feeCount += burnFee;
        uint256 amountOfTo = swap - burnFee;

        IERC20 currencyERC20 = IERC20(_asset.currency);
        currencyERC20.safeTransfer(to, amountOfTo);

        _lastPrice = autionPriceList[autionPriceList.length - 1];

        emit Unwrap(to, tokenId, swap, burnFee);
    }

    function launch() external {
        (address appInstance,,) = getStrategy();
        require(appInstance == msg.sender, "Not app instance");
        address currency0 = address(memeCoin);
        address currency1 = wrapCoin;
        uint256 amount0Max = 700_000_000 * 10 ** 18;
        memeCoin.mint(address(this), amount0Max);

        IERC20(currency1).safeTransfer(vault, 2 ether);

        uint256 amount1Max = IERC20(currency1).balanceOf(address(this)) - feeCount;
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

        IERC20(currency0).approve(address(posm.permit2()), amount0Max);
        IERC20(currency1).approve(address(posm.permit2()), amount1Max);
        posm.permit2().approve(currency0, address(posm), type(uint160).max, type(uint48).max);
        posm.permit2().approve(currency1, address(posm), type(uint160).max, type(uint48).max);
        tokenIdOfLiquidity = posm.nextTokenId();
        PositionManager(posm).multicall(params);
    }

    function claimLPFee() external returns (uint256 balance0, uint256 balance1) {
        address currency0 = address(memeCoin);
        address currency1 = wrapCoin;
        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }
        balance0 = IERC20(currency0).balanceOf(address(this));
        balance1 = IERC20(currency1).balanceOf(address(this));
        bytes memory actions = new bytes(2);
        actions[0] = bytes1(uint8(Actions.DECREASE_LIQUIDITY));
        actions[1] = bytes1(uint8(Actions.TAKE_PAIR));
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(tokenIdOfLiquidity, 0, 0, 0, "");
        params[1] = abi.encode(currency0, currency1, address(this));
        posm.modifyLiquidities(abi.encode(actions, params), block.timestamp + 60);
        balance0 = IERC20(currency0).balanceOf(address(this)) - balance0;
        balance1 = IERC20(currency1).balanceOf(address(this)) - balance1;
        fee0Average = fee0Average + balance0 / MAX_SUPPLY;
        fee1Average = fee1Average + balance1 / MAX_SUPPLY;
    }

    function claimFee(uint256 tokenId, address to) external returns (uint256 fee0, uint256 fee1) {
        (address appInstance,,) = getStrategy();
        require(_isApprovedOrOwner(appInstance, msg.sender, tokenId), "Not token owner or approved");
        address currency0 = address(memeCoin);
        address currency1 = wrapCoin;
        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        fee0 = fee0Average - fee0Debt[tokenId];
        fee1 = fee1Average - fee1Debt[tokenId];
        fee0Debt[tokenId] = fee0Average;
        fee1Debt[tokenId] = fee1Average;
        IERC20(currency0).safeTransfer(to, fee0);
        IERC20(currency1).safeTransfer(to, fee1);
    }

    function claimTransactionFee() external {
        IERC20(wrapCoin).safeTransfer(vault, feeCount);
        feeCount = 0;
    }

    function claimMemeCoin(uint256 tokenId) external {
        require(!memeCoinClaimed[tokenId], "MemeCoin already claimed");
        (address appInstance,,) = getStrategy();
        uint256 nftTotalSupply = IERC721Enumerable(appInstance).totalSupply();
        require(nftTotalSupply == MAX_SUPPLY, "Max supply not reached");
        require(_isApprovedOrOwner(appInstance, msg.sender, tokenId), "Not token owner or approved");

        memeCoin.mint(msg.sender, MEME_COIN_EVERY_WRAPER);
    }

    function description() external pure returns (string memory) {
        return "It's MeMe Launch";
    }

    /**
     * @dev See {IERC7527Agency-getWrapOracle}.
     */
    function getWrapOracle(bytes memory) public view override returns (uint256 swap, uint256 fee) {
        (, Asset memory _asset,) = getStrategy();

        swap = _getPrice();
        if (swap < _asset.basePremium) {
            swap = _asset.basePremium;
        }
        fee = swap / 100;
    }

    /**
     * @dev See {IERC7527Agency-getUnwrapOracle}.
     */
    function getUnwrapOracle(bytes memory) public view override returns (uint256 swap, uint256 fee) {
        swap = autionPriceList[autionPriceList.length - 1];
        fee = swap / 100;
    }

    /**
     * @dev See {IERC7527Agency-getStrategy}.
     */
    function getStrategy() public view override returns (address app, Asset memory asset, bytes memory attributeData) {
        uint256 offset = _getImmutableArgsOffset();
        address currency;
        uint256 basePremium;
        address payable awardFeeRecipient;
        assembly {
            app := shr(0x60, calldataload(add(offset, 0)))
            currency := shr(0x60, calldataload(add(offset, 20)))
            basePremium := calldataload(add(offset, 40))
            awardFeeRecipient := shr(0x60, calldataload(add(offset, 72)))
        }
        asset = Asset(wrapCoin, _basePremium, awardFeeRecipient, 500, 500);
        attributeData = "";
    }

    function tokenIdOfDotAgency() public pure returns (uint256 tokenId) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            tokenId := calldataload(add(offset, 96))
        }
    }

    function _getPrice() internal view returns (uint256 currentPrice) {
        unchecked {
            uint256 deltaT = block.timestamp - _lastMintTime;
            uint256 fixDeltaT = (deltaT << 0x60) / 0x10e;
            uint256 fixLastPrice = (_lastPrice << 0x60) / 0xde0b6b3a7640000;

            if (fixDeltaT == 0) {
                // 0x107ae147ae147b00000000000 = 1.03
                currentPrice = (fixLastPrice * 0x107ae147ae147b00000000000) >> 0x60;
                currentPrice = (0xde0b6b3a7640000 * currentPrice) >> 0x60;
            }

            if (fixDeltaT < 0x4000000000000000000000000 && fixDeltaT != 0) {
                int256 z0 = -1_393_839_815_385_572_048_192_670_772_023_545_036_997_268_998_297_167_936_157
                    / int256(fixDeltaT - 0x7c7617a029722b8e4923f36);
                int256 z1 = 3_271_750_214_091_192_546_354_098_704_229_647_453_725_576_167_699_504_377_075
                    / int256(fixDeltaT - 0xb6e3712fc94f4892c9501e99);
                int256 z2 = -3_755_869_466_880_067_401_998_344_080_125_061_591_817_444_429_913_303_072_540
                    / int256(fixDeltaT - 0x1fffd275302fb8e3ff638dcce);
                int256 z3 = 3_271_890_453_788_590_009_543_841_640_145_940_946_484_557_150_061_130_985_675
                    / int256(fixDeltaT - 0x3491945ea8e28f6a7b23ff516);
                int256 z4 = -1_393_931_385_757_477_734_429_140_141_603_155_757_122_173_786_904_534_869_887
                    / int256(fixDeltaT - 0x3f8389356663abd3f04c62da1);

                int256 zSum = z0 + z1 + z2 + z3 + z4;
                int256 zfSum = z0 * 0x1029951209ae33bc52a69bc07 + z1 * 0x1037974ca821a1a2d842c0f8a
                    + z2 * 0x1051eaf15b5b6b425a74bde60 + z3 * 0x106c3de9966ae47225c5118c2 + z4 * 0x107a3f3bc78bff43ceae1c608;

                currentPrice = (fixLastPrice * uint256(zfSum / zSum)) >> 0x60;
                currentPrice = (0xde0b6b3a7640000 * currentPrice) >> 0x60;
            }

            if (fixDeltaT >= 0x4000000000000000000000000) {
                int256 expDeltaT = (int256(fixDeltaT - 0x4000000000000000000000000) * (-0.002463 ether)) >> 0x60;
                fixLastPrice = (fixLastPrice * 0x107ae147ae147b00000000000) >> 0x60;

                currentPrice = uint256(int256(fixLastPrice) * expDeltaT.expWad()) >> 0x60;
            }

            if (currentPrice < _lastPrice) currentPrice = _lastPrice;
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }

    function _isApprovedOrOwner(address app, address spender, uint256 tokenId) internal view virtual returns (bool) {
        IERC721Enumerable _app = IERC721Enumerable(app);
        address _owner = _app.ownerOf(tokenId);
        return (spender == _owner || _app.isApprovedForAll(_owner, spender) || _app.getApproved(tokenId) == spender);
    }
}
