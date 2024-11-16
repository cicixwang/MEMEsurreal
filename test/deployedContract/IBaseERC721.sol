// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

/**
 * @title IBaseERC721
 * @author Premium DAO
 */
interface IBaseERC721 {
    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    error ZeroSpender();
    error SignatureExpired();
    error SignatureInvalid();
    /**
     * @notice Implementation of an EIP-712 permit function for an ERC-721 NFT. We don't need to check
     * if the tokenId exists, since the function calls ownerOf(tokenId), which reverts if the tokenId does
     * not exist.
     *
     * @param spender The NFT spender.
     * @param tokenId The NFT token ID to approve.
     * @param sig The EIP712 signature struct.
     */

    function permit(address spender, uint256 tokenId, EIP712Signature calldata sig) external;

    /**
     * @notice Implementation of an EIP-712 permit-style function for ERC-721 operator approvals. Allows
     * an operator address to control all NFTs a given owner owns.
     *
     * @param owner The owner to set operator approvals for.
     * @param operator The operator to approve.
     * @param approved Whether to approve or revoke approval from the operator.
     * @param sig The EIP712 signature struct.
     */
    function permitForAll(address owner, address operator, bool approved, EIP712Signature calldata sig) external;

    /**
     * @notice Checks whether a given spender is approved to spend a given tokenId, or is the owner of the
     * tokenId.
     *
     * @param spender The address of the spender.
     * @param tokenId The tokenId to check.
     *
     * @return bool Whether the spender is approved or the owner of the tokenId.
     */
    function isAuthorized(address spender, uint256 tokenId) external view returns (bool);

    /**
     * @notice Returns the domain separator for this NFT contract.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @notice Returns the next tokenId that will be minted.
     *
     * @return uint256 The next tokenId.
     */
    function nextTokenId() external view returns (uint256);
}
