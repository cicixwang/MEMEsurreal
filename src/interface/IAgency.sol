// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

interface IAgency {
    // The `tokenIdOfDotAgency` is the tokenID of the `Deployer` contract.
    function tokenIdOfDotAgency() external pure returns (uint256 id);

    // Contract Implementer
    function creator() external view returns (address);

    // The `perTokenReward` is the reward for each token.
    function perTokenReward() external view returns (uint256);

    // The `debtsOfTokenId` is the debt of the tokenID.
    function debtsOfTokenId(uint256 tokenId) external view returns (uint256);
}
