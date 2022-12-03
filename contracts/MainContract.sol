// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IXReceiver.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MainContract is IXReceiver {

    struct ChildContractDetails {
        // connext details
        address connextContractAddress;
        uint32 domain;

        // child contract details
        address childContractAddress;
    }

    struct DaoProposal{
        string daoName;
        string proposalTitle;
        // Uploaded to IPFS
        string proposalDescHash;
        uint256 noOfOptions;
        uint voteEndTime;
    }

    struct VoteDetails {
        uint256 optionId;
        uint256 proposalId;
        address voter;
        uint256 amount;
    }

    DaoProposal[] public daoProposals;

    uint32[] domains;
    mapping(uint32 => ChildContractDetails) public mapDomainToContract;

    mapping(uint256 => mapping(address => VoteDetails)) public mapProposalIdToVoterToVoteDetails;
    mapping(uint256 => address[]) public mapProposalIdToVoters;

    address public owner;
    IConnext public immutable connext;

    constructor(IConnext _connext) {
        owner = msg.sender;
        connext = _connext;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addChildContractAddress(
        address _connextContractAddress,
        uint32 _domain,
        address _childContractAddress
    ) external onlyOwner {
        ChildContractDetails memory newEntry;
        newEntry.connextContractAddress = _connextContractAddress;
        newEntry.domain = _domain;
        newEntry.childContractAddress = _childContractAddress;
        mapDomainToContract[_domain] = newEntry;

        domains.push(_domain);
    }

    function createDaoProposal(
        string memory _daoName,
        string memory _proposalTitle,
        string memory _proposalDescHash,
        uint256 _noOfOptions,
        uint256 _voteTimeEnd
    ) external {
        DaoProposal memory newProposal;
        newProposal.daoName = _daoName;
        newProposal.proposalTitle = _proposalTitle;
        newProposal.proposalDescHash = _proposalDescHash;
        newProposal.noOfOptions = _noOfOptions;
        newProposal.voteEndTime = _voteTimeEnd;

        daoProposals.push(newProposal);
    }

    function xReceive(
        bytes32 _transferId, 
        uint256 _amount, 
        address _asset, 
        address _originSender, 
        uint32 _origin, 
        bytes memory _callData
    ) external returns (bytes memory) { 
        (string memory purpose, uint256 proposalId,  address voter, uint256 tokenQuantity, uint256 optionId) = abi.decode(_callData, (string, uint256, address, uint256, uint256));

        if(keccak256(bytes(purpose)) == keccak256(bytes("vote"))) {
            require(mapProposalIdToVoterToVoteDetails[proposalId][voter].amount == 0, "Already voted");
            require(daoProposals[proposalId].voteEndTime > block.timestamp, "Voting time ended");
            require(optionId < daoProposals[proposalId].noOfOptions, "Invalid option id");
            
            mapProposalIdToVoterToVoteDetails[proposalId][voter].optionId = optionId;
            mapProposalIdToVoterToVoteDetails[proposalId][voter].proposalId = proposalId;
            mapProposalIdToVoterToVoteDetails[proposalId][voter].voter = voter;
            mapProposalIdToVoterToVoteDetails[proposalId][voter].amount = tokenQuantity;

            mapProposalIdToVoters[proposalId].push(voter);

            uint256 votedDomain = _origin;
            // Get tokens count from other contracts
            for(uint256 i = 0; i < domains.length; i++){
                if(votedDomain == domains[i])
                    continue;
                
                bytes memory callData = abi.encode("send_count", proposalId, voter);
                connext.xcall{value: 0}(
                    domains[i],         // _destination: Domain ID of the destination chain
                    mapDomainToContract[domains[i]].childContractAddress,            // _to: address of the target contract
                    address(0),        // _asset: use address zero for 0-value transfers
                    msg.sender,        // _delegate: address that can revert or forceLocal on destination
                    0,                 // _amount: 0 because no funds are being transferred
                    0,                 // _slippage: can be anything between 0-10000 because no funds are being transferred
                    callData           // _callData: the encoded calldata to send
                );
            }
        } else if (keccak256(bytes(purpose)) == keccak256(bytes("send_count"))) {
            mapProposalIdToVoterToVoteDetails[proposalId][voter].amount += tokenQuantity;
        }

    }

    function getProposalResult(uint256 _proposalId) external view returns (uint256[] memory) {
        require(daoProposals[_proposalId].voteEndTime < block.timestamp, "Voting time not ended");
        
        uint256[] memory result = new uint256[](daoProposals[_proposalId].noOfOptions);
        for(uint256 i = 0; i < mapProposalIdToVoters[_proposalId].length; i++){
            address userAddress = mapProposalIdToVoters[_proposalId][i];
            result[mapProposalIdToVoterToVoteDetails[_proposalId][userAddress].optionId] += mapProposalIdToVoterToVoteDetails[_proposalId][userAddress].amount;
        }
        return result;
    }
}
