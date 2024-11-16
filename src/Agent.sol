// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.25;

import { ERC721 } from "solady/src/tokens/ERC721.sol";
import { ERC2981 } from "solady/src/tokens/ERC2981.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { BaseERC721 } from "./BaseERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Initializable } from "@openzeppelin/contractsUpgradeable/proxy/utils/Initializable.sol";
import { IAgent } from "./interfaces/IAgent.sol";
import { IANS } from "ANS@1.0.0/src/IANS.sol";
import { BaseTokenURISettings } from "tokenURISettingsUpgradeable@2.0.0/src/BaseTokenURISettings.sol";
import { TokenURISettingsERC3668 } from "tokenURISettingsUpgradeable@2.0.0/src/extensions/TokenURISettingsERC3668.sol";
import { ITokenURIEngine } from "tokenURISettingsUpgradeable@2.0.0/src/ITokenURIEngine.sol";
import { IERC7527App } from "./interfaces/IERC7527App.sol";
import { IERC7527Agency, Asset } from "./interfaces/IERC7527Agency.sol";
import { IWrapV1Factory } from "./interfaces/IWrapV1Factory.sol";

contract Agent is BaseERC721, TokenURISettingsERC3668, IAgent, IERC7527App, ERC2981, Initializable {
    /// storage
    uint256 constant MAX_SUPPLY = 3;
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // Total number of tokens minted.
    uint256 private _totalSupply;
    // Next token id to be minted.
    uint256 private _nextTokenId;
    // The implementation of the agent.
    address private immutable _agentImplementation;
    // The address of the instance of a contract implementing the `ERC7527Agency` interface.
    address payable private _agency;
    // The address of the `DotAgency`.
    address public immutable dotAgency;
    // The address of the `ERC7527Factory`.
    address public immutable factory;

    using Address for address;

    /// modifier

    // Check if the msg.sender is the owner of the `DotAgency` indentified by the `tokenId`.
    modifier isProxyAgency() override {
        IERC721 agency_ = IERC721(dotAgency);
        address owner_ = agency_.ownerOf(tokenIdOfDotAgency());
        address msgSender_ = msg.sender;
        require(
            owner_ == msgSender_ || agency_.isApprovedForAll(owner_, msgSender_)
                || agency_.getApproved(tokenIdOfDotAgency()) == msgSender_,
            "only agency"
        );
        _;
    }

    // Check if the msg.sender is an instance of a contract implementing the `ERC7527Agency` interface.
    modifier onlyAgency() {
        if (msg.sender != _getAgency()) revert AgentCallerIsNotAgency(msg.sender);
        _;
    }

    constructor(address agency_, address factory_) initializer {
        // Set the address of the `DotAgency`.
        dotAgency = agency_;
        // Set the address of the `ERC7527Factory`.
        factory = factory_;

        // Set the implementation of the agent.
        _agentImplementation = address(this);

        // Initialize the ERC721 just for implementation of the agent.
        _name = "AgentImplementation";
        _symbol = "Agent";
    }

    function iconstructor() external {
        // Check if the agent is deployed.
        if (IWrapV1Factory(factory).nonce(tokenIdOfDotAgency(), _agentImplementation) != 0) {
            revert AgentCannotRedeploy(tokenIdOfDotAgency());
        }

        if (bytes(_name).length != 0) revert AgentInvalidInitialization();
        bytes32 node = IANS(dotAgency).getNode(tokenIdOfDotAgency());
        bytes memory fullname = IANS(dotAgency).getName(node);
        bytes memory namelabel = new bytes(fullname.length - 7);
        assembly {
            mstore(add(namelabel, 0x20), mload(add(fullname, 0x20)))
        }

        // During the deployment of the proxy, initialize ERC721Enumerable.
        _name = string(bytes.concat(bytes("meme."), namelabel));
        _symbol = string(namelabel);

        address erc6551AccountImp = abi.decode(dotAgency.functionCall(bytes.concat(bytes4(0xd919e678))), (address));
        bytes memory data = abi.encodeWithSelector(
            bytes4(0x246a0021),
            erc6551AccountImp,
            bytes32("DEFAULT_ACCOUNT_SALT"),
            block.chainid,
            dotAgency,
            tokenIdOfDotAgency()
        );
        address accountOfDotAgency = abi.decode(dotAgency.functionCall(data), (address));
        _setDefaultRoyalty(accountOfDotAgency, 250);
    }

    /**
     *
     * @dev See {IERC7527-setAgency}.
     */
    function setAgency(address payable agency) external override {
        require(_getAgency() == address(0), "already set");
        _agency = agency;
    }

    /**
     *
     * @dev See {IERC7527-burn}.
     */
    function burn(uint256 tokenId, bytes calldata) external override onlyAgency {
        if (_totalSupply >= MAX_SUPPLY) revert AgentMaxSupplyOverflow(MAX_SUPPLY);
        _burn(tokenId);
        --_totalSupply;
    }

    /**
     *
     * @dev See {IERC7527-mint}.
     */
    function mint(address to, bytes calldata) external override onlyAgency returns (uint256 tokenId) {
        if (_totalSupply >= MAX_SUPPLY) revert AgentMaxSupplyOverflow(MAX_SUPPLY);

        _nextTokenId = _nextTokenId + 1;
        tokenId = _nextTokenId;
        _mint(to, tokenId);
        _totalSupply = _totalSupply + 1;
        if (_totalSupply == MAX_SUPPLY) {
            address(_agency).functionCall(abi.encodeWithSelector(bytes4(0x01339c21)));
        }
        emit Mint(to, tokenId);
    }

    /**
     *
     * @dev See {IBaseERC721-nextTokenId}.
     */
    function nextTokenId() external view override returns (uint256) {
        return _nextTokenId;
    }

    /**
     *
     * @dev See {IBaseERC7527-getName}.
     */
    function getName(uint256 tokenId) external pure override returns (string memory) {
        return Strings.toString(tokenId);
    }

    /**
     *
     * @dev See {IBaseERC7527-getAgency}.
     */
    function getAgency() external view override returns (address payable) {
        return _getAgency();
    }

    /**
     *
     * @dev See {IBaseERC7527-getMaxSupply}.
     *
     */
    function getMaxSupply() public pure override returns (uint256 maxSupply) {
        maxSupply = MAX_SUPPLY;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function name() public view override returns (string memory) {
        (, Asset memory asset,) = IERC7527Agency(_getAgency()).getStrategy();
        string memory symbolOfCurrency;
        if (asset.currency == address(0)) {
            symbolOfCurrency = "ETH";
        } else {
            symbolOfCurrency = IERC20Metadata(asset.currency).symbol();
        }
        return string(abi.encodePacked(_name, "/", symbolOfCurrency));
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     *
     * @param tokenId The tokenId of the agent.
     * @return output The tokenURI of the agent which is a JSON string.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory output) {
        _exists(tokenId);
        ITokenURIEngine engine = ITokenURIEngine(getTokenURIEngine(tokenId));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"#"',
                        Strings.toString(tokenId),
                        '", "description": "Powered by Premium.", ',
                        engine.render(tokenId),
                        "}"
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId)
            || interfaceId == type(IERC7527App).interfaceId;
    }

    function tokenIdOfDotAgency() public pure returns (uint256 tokenId) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            tokenId := calldataload(add(offset, 0x20))
        }
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, BaseTokenURISettings) returns (address) {
        return ERC721.ownerOf(tokenId);
    }

    function _getAgency() internal view returns (address payable) {
        return _agency;
    }

    function _isAuthorized(
        address owner,
        address spender,
        uint256 tokenId
    )
        internal
        view
        override(BaseERC721, BaseTokenURISettings)
        returns (bool)
    {
        return super._isAuthorized(owner, spender, tokenId);
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }
}
