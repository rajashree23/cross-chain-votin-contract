// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IXReceiver.sol";


contract ChildContract is IXReceiver {
    address owner;
    address tokenAddress;
    IConnext public immutable connext;

    struct ParentContractDetails {
        // connext details
        uint32 parentDomain;

        // parent contract details
        address parentContractAddress;
    }
    ParentContractDetails parentContract; 

    constructor(IConnext _connext, address _tokenAddress) {
        owner = msg.sender;
        connext = _connext;
        tokenAddress = _tokenAddress;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setParentContractDetails(uint32 _parentDomain, address _parentContractAddress) public onlyOwner {
        parentContract.parentDomain = _parentDomain;
        parentContract.parentContractAddress = _parentContractAddress;
    }

    function getTokenQuantity(address _user) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(_user);
    }

    //send vote to the main contract


    function vote(uint256 _proposalId, uint256 _optionId) external {
        // Get ERC 20 tokens count of msg.sender
        uint256 tokenQuantity = getTokenQuantity(msg.sender);

        bytes memory callData = abi.encode("vote", _proposalId, _optionId, tokenQuantity, msg.sender);
        IConnext(connext).xcall{value: 0}(
            parentContract.parentDomain,         // _destination: Domain ID of the destination chain
            parentContract.parentContractAddress,            // _to: address of the target contract
            address(0),        // _asset: address of the token contract
            msg.sender,        // _delegate: address that can revert or forceLocal on destination
            0,                 // _amount: 0 because no funds are being transferred
            0,                 // _slippage: can be anything between 0-10000 because no funds are being transferred
            callData           // _callData: the encoded calldata to send
        );
    }
    
    function xReceive(
        bytes32 _transferId, 
        uint256 _amount, 
        address _asset, 
        address _originSender, 
        uint32 _origin, 
        bytes memory _callData
    ) external returns (bytes memory) {
        (string memory purpose, uint256 proposalId, address voter, uint256 optionId) = abi.decode(_callData, (string, uint256, address, uint256));

        if (keccak256(bytes(purpose)) == keccak256(bytes("send_count"))) {
            uint256 tokenQuantity = getTokenQuantity(voter);
            bytes memory callData = abi.encode(purpose, proposalId, voter, optionId, tokenQuantity);
            IConnext(connext).xcall{value: 0}(
                parentContract.parentDomain,         // _destination: Domain ID of the destination chain
                parentContract.parentContractAddress,            // _to: address of the target contract
                address(0),        // _asset: use address zero for 0-value transfers
                msg.sender,        // _delegate: address that can revert or forceLocal on destination
                0,                 // _amount: 0 because no funds are being transferred
                0,                 // _slippage: can be anything between 0-10000 because no funds are being transferred
                callData           // _callData: the encoded calldata to send
            );
        }
    }
}