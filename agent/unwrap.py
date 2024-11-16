import os
import sys
import time

from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI
from langgraph.checkpoint.memory import MemorySaver
from langgraph.prebuilt import create_react_agent

# Import CDP Agentkit Langchain Extension.
from cdp_langchain.agent_toolkits import CdpToolkit
from cdp_langchain.utils import CdpAgentkitWrapper
from cdp_langchain.tools import CdpTool

from collections.abc import Callable

from cdp import Wallet
from pydantic import BaseModel, Field


UNWRAP_TOKEN_PROMPT = """
This tool will unwrap an ERC7527 NFT back to the original ERC20 token using the smart contract deployed on Base testnet. It takes the token ID of the NFT you want to unwrap as input. The user must be the owner of the NFT to unwrap it."""


class UnwrapTokenInput(BaseModel):
     """Input argument schema for wrap token action."""



def unwrap_token(wallet: Wallet) -> str:
    """Unwrap an ERC7527 NFT back to ERC20 token via contract invocation.

    Args:
        wallet (Wallet): The wallet to execute the unwrap from.
        token_id (int): The ID of the ERC7527 NFT to unwrap, e.g. `1`.

    Returns:
        str: A message containing the unwrap transaction details.
    """

    encoded_data = "0x00"

    unwrap_args = {"to": wallet.default_address.address_id, 
                    "data": encoded_data}

    abi = [
        {
            "type": "constructor",
            "inputs": [
                {
                    "name": "dotAgency_",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "posm_",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "wrapCoin_",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "usdt_",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "vault_",
                    "type": "address",
                    "internalType": "address"
                }
            ],
            "stateMutability": "nonpayable"
        },
        {
            "type": "receive",
            "stateMutability": "payable"
        },
        {
            "type": "function",
            "name": "claimFee",
            "inputs": [
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "to",
                    "type": "address",
                    "internalType": "address"
                }
            ],
            "outputs": [
                {
                    "name": "fee0",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "fee1",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "claimLPFee",
            "inputs": [],
            "outputs": [
                {
                    "name": "balance0",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "balance1",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "claimMemeCoin",
            "inputs": [
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "claimTransactionFee",
            "inputs": [],
            "outputs": [],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "description",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "string",
                    "internalType": "string"
                }
            ],
            "stateMutability": "pure"
        },
        {
            "type": "function",
            "name": "dotAgency",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "address",
                    "internalType": "address"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "fee0Average",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "fee0Debt",
            "inputs": [
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [
                {
                    "name": "fee0Debt",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "fee1Average",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "fee1Debt",
            "inputs": [
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [
                {
                    "name": "fee1Debt",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "feeCount",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "getStrategy",
            "inputs": [],
            "outputs": [
                {
                    "name": "app",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "asset",
                    "type": "tuple",
                    "internalType": "struct Asset",
                    "components": [
                        {
                            "name": "currency",
                            "type": "address",
                            "internalType": "address"
                        },
                        {
                            "name": "basePremium",
                            "type": "uint256",
                            "internalType": "uint256"
                        },
                        {
                            "name": "feeRecipient",
                            "type": "address",
                            "internalType": "address"
                        },
                        {
                            "name": "mintFeePercent",
                            "type": "uint16",
                            "internalType": "uint16"
                        },
                        {
                            "name": "burnFeePercent",
                            "type": "uint16",
                            "internalType": "uint16"
                        }
                    ]
                },
                {
                    "name": "attributeData",
                    "type": "bytes",
                    "internalType": "bytes"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "getUnwrapOracle",
            "inputs": [
                {
                    "name": "",
                    "type": "bytes",
                    "internalType": "bytes"
                }
            ],
            "outputs": [
                {
                    "name": "swap",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "fee",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "getWrapOracle",
            "inputs": [
                {
                    "name": "",
                    "type": "bytes",
                    "internalType": "bytes"
                }
            ],
            "outputs": [
                {
                    "name": "swap",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "fee",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "iconstructor",
            "inputs": [],
            "outputs": [],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "launch",
            "inputs": [],
            "outputs": [],
            "stateMutability": "nonpayable"
        },
        {
            "type": "function",
            "name": "memeCoin",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "address",
                    "internalType": "contract MeMeCoin"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "memeCoinClaimed",
            "inputs": [
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "outputs": [
                {
                    "name": "claimed",
                    "type": "bool",
                    "internalType": "bool"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "posm",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "address",
                    "internalType": "contract PositionManager"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "tokenIdOfDotAgency",
            "inputs": [],
            "outputs": [
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "pure"
        },
        {
            "type": "function",
            "name": "tokenIdOfLiquidity",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "unwrap",
            "inputs": [
                {
                    "name": "to",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "data",
                    "type": "bytes",
                    "internalType": "bytes"
                }
            ],
            "outputs": [],
            "stateMutability": "payable"
        },
        {
            "type": "function",
            "name": "usdt",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "address",
                    "internalType": "address"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "vault",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "address",
                    "internalType": "address"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "function",
            "name": "wrap",
            "inputs": [
                {
                    "name": "to",
                    "type": "address",
                    "internalType": "address"
                },
                {
                    "name": "data",
                    "type": "bytes",
                    "internalType": "bytes"
                }
            ],
            "outputs": [
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ],
            "stateMutability": "payable"
        },
        {
            "type": "function",
            "name": "wrapCoin",
            "inputs": [],
            "outputs": [
                {
                    "name": "",
                    "type": "address",
                    "internalType": "address"
                }
            ],
            "stateMutability": "view"
        },
        {
            "type": "event",
            "name": "Unwrap",
            "inputs": [
                {
                    "name": "to",
                    "type": "address",
                    "indexed": True,
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "indexed": True,
                    "internalType": "uint256"
                },
                {
                    "name": "premium",
                    "type": "uint256",
                    "indexed": False,
                    "internalType": "uint256"
                },
                {
                    "name": "fee",
                    "type": "uint256",
                    "indexed": False,
                    "internalType": "uint256"
                }
            ],
            "anonymous": False
        },
        {
            "type": "event",
            "name": "Wrap",
            "inputs": [
                {
                    "name": "to",
                    "type": "address",
                    "indexed": True,
                    "internalType": "address"
                },
                {
                    "name": "tokenId",
                    "type": "uint256",
                    "indexed": True,
                    "internalType": "uint256"
                },
                {
                    "name": "premium",
                    "type": "uint256",
                    "indexed": False,
                    "internalType": "uint256"
                },
                {
                    "name": "fee",
                    "type": "uint256",
                    "indexed": False,
                    "internalType": "uint256"
                }
            ],
            "anonymous": False
        },
        {
            "type": "error",
            "name": "AddressEmptyCode",
            "inputs": [
                {
                    "name": "target",
                    "type": "address",
                    "internalType": "address"
                }
            ]
        },
        {
            "type": "error",
            "name": "AddressInsufficientBalance",
            "inputs": [
                {
                    "name": "account",
                    "type": "address",
                    "internalType": "address"
                }
            ]
        },
        {
            "type": "error",
            "name": "FailedInnerCall",
            "inputs": []
        },
        {
            "type": "error",
            "name": "ReentrancyGuardReentrantCall",
            "inputs": []
        },
        {
            "type": "error",
            "name": "SafeERC20FailedOperation",
            "inputs": [
                {
                    "name": "token",
                    "type": "address",
                    "internalType": "address"
                }
            ]
        },
        {
            "type": "error",
            "name": "WrapMeMeLaunchConstructed",
            "inputs": []
        },
        {
            "type": "error",
            "name": "WrapMeMeLaunchExceededSlippagePrice",
            "inputs": [
                {
                    "name": "required",
                    "type": "uint256",
                    "internalType": "uint256"
                },
                {
                    "name": "available",
                    "type": "uint256",
                    "internalType": "uint256"
                }
            ]
        },
        {
            "type": "error",
            "name": "WrapMeMeLaunchNotOwnerAndNotApproved",
            "inputs": [
                {
                    "name": "",
                    "type": "address",
                    "internalType": "address"
                }
            ]
        }
    ]

    try:
        unwrap_invocation = wallet.invoke_contract(
            contract_address="0xfAa8e5B0Ef93dF841B37807E13Fe77Ff54986Ac2",
            abi=abi,
            method="unwrap",
            args=unwrap_args,
            amount=12,
            asset_id="0x548A7404C1089c2B0b0b8dfe25784446c7d30B22"
        ).wait()
    except Exception as e:
        return f"Error unwrapping NFT: {e!s}"

    return f"Unwrapped ERC7527 NFT (ID: {token_id}) back to ERC20 token on network {wallet.network_id}.\nTransaction hash: {unwrap_invocation.transaction.transaction_hash}\nTransaction link: {unwrap_invocation.transaction.transaction_link}"


