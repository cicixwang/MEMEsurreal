// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import { ERC721 } from "solady/src/tokens/ERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IBaseERC721 } from "./interfaces/IBaseERC721.sol";

/**
 * @title BaseERC721
 * @author Premium DAO
 */
abstract contract BaseERC721 is ERC721, IBaseERC721, ERC721Holder {
    bytes32 internal constant _EIP712_REVISION_HASH = keccak256("1");
    bytes32 internal constant _PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 internal constant _PERMIT_FOR_ALL_TYPEHASH =
        keccak256("PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)");
    bytes32 internal constant _EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    mapping(address => uint256) public sigNonces;

    /// @inheritdoc IBaseERC721

    function permit(address spender, uint256 tokenId, EIP712Signature calldata sig) external override {
        if (spender == address(0)) revert ZeroSpender();
        address owner = ownerOf(tokenId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenId, sigNonces[owner]++, sig.deadline))
                ),
                owner,
                sig
            );
        }
        _approve(owner, spender, tokenId);
    }

    /// @inheritdoc IBaseERC721
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        EIP712Signature calldata sig
    )
        external
        override
    {
        if (operator == address(0)) revert ZeroSpender();
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            _PERMIT_FOR_ALL_TYPEHASH, owner, operator, approved, sigNonces[owner]++, sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        _setApprovalForAll(owner, operator, approved);
    }

    /// @inheritdoc IBaseERC721
    function getDomainSeparator() external view override returns (bytes32) {
        return _calculateDomainSeparator();
    }

    /// @inheritdoc IBaseERC721
    function isAuthorized(address spender, uint256 tokenId) external view virtual override returns (bool) {
        return _isAuthorized(ownerOf(tokenId), spender, tokenId);
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        EIP712Signature calldata sig
    )
        internal
        view
    {
        if (sig.deadline < block.timestamp) revert SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress) {
            revert SignatureInvalid();
        }
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name())), _EIP712_REVISION_HASH, block.chainid, address(this)
            )
        );
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(abi.encodePacked("\x19\x01", _calculateDomainSeparator(), hashedMessage));
        }
        return digest;
    }

    function _isAuthorized(address, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return ERC721._isApprovedOrOwner(spender, tokenId) || isApprovedForAll(ownerOf(tokenId), spender);
    }
}
