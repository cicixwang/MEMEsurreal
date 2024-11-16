// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IAgent {
    // errors
    error AgentCallerIsNotAgency(address caller);
    error AgentCannotRedeploy(uint256 tokenId);
    error AgentMaxSupplyOverflow(uint256 maxSupply);
    /**
     * @dev The contract is already initialized.
     */
    error AgentInvalidInitialization();

    // events
    event Mint(address indexed to, uint256 indexed tokenId);
}
