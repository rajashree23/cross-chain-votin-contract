// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface xVotingSourceDestination {
     
    function vote(string memory uid, uint optionID, address _voter) external;
}

contract VotingSource {
    // mapping to store chain id and corresponding address;
    struct connextContractDetails {
        //connext contract address
        address connextContractAddress;
        //domain
        uint32 domain;
        //deployer address
        address destinationContractAddress;
    }

    struct daoProposal{
        string daoName;
        string proposalTitle;
        string proposalDescription;
        uint voteEndTime;
    }


    mapping(uint256 => connextContractDetails) public mapChainIdToContract;
    address public owner;
    IConnext public connext;

    constructor(IConnext _connext) {
        owner = msg.sender;
        connext = _connext;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addConnextAddress(
        uint256 _chainId,
        address _contractAddress,
        uint32 _domain,
        address _destinationContractAddress
    ) external onlyOwner {
        connextContractDetails memory newEntry;
        newEntry.connextContractAddress = _contractAddress;
        newEntry.domain = _domain;
        newEntry.destinationContractAddress = _destinationContractAddress;
        mapChainIdToContract[_chainId] = newEntry;
    }

     function xVote(
        string[] memory _prop_id,
     
        uint256[] memory _chainIds
    ) public {
       
        
        bytes4 selector = bytes4(
            keccak256("vote(string,string,address)")
        );
   

        for (uint8 i = 0; i < _chainIds.length; i++) {
                 bytes memory callData = abi.encodeWithSelector(
            selector,
            // Function data
            _prop_id[i],
            i,
            msg.sender
        );
            //get domain and deployer address
            connextContractDetails memory details = mapChainIdToContract[
                _chainIds[i]
            ];
            if (_chainIds[i] == 80001) {
                xVotingSourceDestination(details.connextContractAddress).vote(
                    // function data needs to be changed
                  _prop_id[i],
                  i,
                  msg.sender
                );
            } else {
                //define params as per connext
                // CallParams memory callParams = CallParams({
                //     to: details.destinationContractAddress,
                //     callData: callData,
                //     originDomain: 1735353714, //originDomain -> polygon Mumbai,
                //     destinationDomain: details.domain, // gorlie
                //     agent: msg.sender, // address allowed to execute transaction on destination side in addition to relayers
                //     recovery: msg.sender, // fallback address to send funds to if execution fails on destination side
                //     forceSlow: false, // option to force slow path instead of paying 0.05% fee on fast liquidity transfers
                //     receiveLocal: false, // option to receive the local bridge-flavored asset instead of the adopted asset
                //     callback: address(0), // zero address because we don't expect a callback
                //     callbackFee: 0, // fee paid to relayers for the callback; no fees on testnet
                //     relayerFee: 0, // fee paid to relayers for the forward call; no fees on testnet
                //     destinationMinOut: 0 // not sending funds so minimum can be 0
                // });
                // // wrap it in xcall format
                // XCallArgs memory xcallArgs = XCallArgs({
                //     params: callParams,
                //     transactingAsset: address(0), // 0 address is the native gas token
                //     transactingAmount: 0, // not sending funds with this calldata-only xcall
                //     originMinOut: 0 // not sending funds so minimum can be 0
                // });
                // call the deployer contracts
                // relayer Fee is 0 due to test net
                IConnext(connext).xcall{value: 0}(
                    details.domain,
                    details.destinationContractAddress,
                    address(0), //token address
                    msg.sender,
                    0,
                    0,
                    callData
                );
            }
        }
    }
}
