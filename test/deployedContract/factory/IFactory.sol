    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFactory {
    /**
     * @dev Returns the address of the app associated with the `tokenId` and `implementation`.
     * @param instance The address of the app instance.
     * @param tokenId The identifier of the non-fungible token.
     * @return app The address of the app implementation.
     */
    function app(address instance, uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the address of the app implementation associated with the `tokenId` and `nonce`.
     * @param implementation The address of the ERC7527App implementation.
     * @param tokenId The identifier of the non-fungible token.
     * @param nonce The nonce of the function.
     * @return appInst The address of the app instance.
     */
    function appInst(address implementation, uint256 tokenId, uint256 nonce) external view returns (address);

    /**
     * @dev Returns the address of the agency associated with the `tokenId` and `implementation`.
     * @param instance The address of the agency instance.
     * @param tokenId The identifier of the non-fungible token.
     * @return agency The address of the agency implementation.
     */
    function agency(address instance, uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the address of the agency implementation associated with the `tokenId` and `nonce`.
     * @param implementation The address of the ERC7527Agency implementation.
     * @param tokenId The identifier of the non-fungible token.
     * @param nonce The nonce of the function.
     * @return agencyInst The address of the agency instance.
     */
    function agencyInst(address implementation, uint256 tokenId, uint256 nonce) external view returns (address);

    /**
     * @dev Returns the once of the function associated with the `tokenId` and `implementation`.
     * @param tokenId The identifier of the non-fungible token.
     * @param implementation The address of the ERC7527App implementation.
     */
    function nonce(uint256 tokenId, address implementation) external view returns (uint256);
}
