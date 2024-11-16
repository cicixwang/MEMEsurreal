// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IDotAgency {
    // errors
    error DotAgencyExceededSlippagePrice(uint256 required, uint256 available);
    error DotAgencyCommittLocked(uint256 priceNonce);
    // events

    event Mint(address indexed to, uint256 indexed tokenId, string indexed name, uint256 price);

    /**
     * @dev Mint a new token with the given name.
     * @param name The name of the token without the ".agency" suffix.
     * @notice Set the slippage in the frontend.
     * @return id The tokenId of the newly minted token.
     */
    function mint(string calldata name, uint256 priceNonce) external payable returns (uint256);
    function commit() external returns (uint256);
    // Returns the address of the WrapCoin contract.
    function wrapCoin() external view returns (address);
    // Returns the address of the WrapCoinClaim contract;
    function wrapCoinClaim() external view returns (address);
    // Returns the current agency NFT price
    function getPrice() external view returns (uint256);
    // Returns the node of the given tokenId.
    function getNode(uint256) external view returns (bytes32);
    function getBidWrapPrice(uint256) external view returns (uint256);
    function getCommitBlock(uint256) external view returns (uint256);
    // Returns the WrapCoin mint number
    function wrapCoinGrowthOracle() external view returns (uint256);
}
