// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Vote is ERC20{
    using Counters for Counters.Counter;
    Counters.Counter private tokenCount;

    address public  owner;
    address newOwner;
    uint256 public  price;
    uint256 contractBalance;
    string public  _tokenURI;
    string _tokenURIBulk;

    uint256 public constant MAX_CAP = 200;

    event OwnershipTransferred(address);
    event OwnershipClaimed(address);
    event Minted(uint256, address);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can invoke this function");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _owner,
        string memory tokenURILocal,
        uint256 _price
    )ERC20(name, symbol)  {
        owner = _owner;
        _tokenURI = tokenURILocal;
        price = _price;
        name=name;
        symbol=symbol;
    }

    function grantOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be a zero address");
        newOwner = _newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function claimOwnerShip() external {
        require(
            msg.sender == newOwner,
            "Only new owner can call this function"
        );
        owner = msg.sender;

        emit OwnershipClaimed(msg.sender);
    }

    function setNFTPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setTokenURIForBulkMint(string memory _tokenURIBulkMint)
        external
        onlyOwner
    {
        _tokenURIBulk = _tokenURIBulkMint;
    }

  
    function withdrawFunds() external onlyOwner {
        (bool sent, ) = address(msg.sender).call{value: contractBalance}("");

        require(sent, "Ether not sent");
    }
}

//Factory Contract
contract xVotingSourceDestination {
    // struct NFTDetails {
    //     string name;
    //     string symbol;
    //     string tokenURI;
    //     uint256 price;
    // }

    // mapping(uint256 => NFTDetails) public nftMapping;

    // function deploy(
    //     string memory name,
    //     string memory symbol,
    //     string memory tokenURI,
    //     uint256 price
    // ) external {
    //     NFTDetails memory newEntry;
    //     newEntry.name = name;
    //     newEntry.symbol = symbol;
    //     newEntry.tokenURI = tokenURI;
    //     newEntry.price = price;

    //     nftMapping[++index] = newEntry;
    // }

    struct _contract {
        uint256 id;
        address owner;
        address contractAddress;
    }

    _contract[] Contracts;
    mapping(address => address[]) addressContractMap;

    event LaunchNFTContract(address indexed, address indexed);

    constructor() {}

 

    //Returns the NFT contract addresses for a particular owner
    function getContract() external view returns (address[] memory) {
        return (addressContractMap[msg.sender]);
    }

    //Get all the contract addresses of the various NFT Contracts
    function getAllContracts() external view returns (_contract[] memory) {
        return Contracts;
    }
}

// written for Solidity version 0.4.18 and above that doesnt break functionality

contract Voting {
    // an event that is called whenever a Candidate is added so the frontend could
    // appropriately display the candidate with the right element id (it is used
    // to vote for the candidate, since it is one of arguments for the function "vote")
    event AddedCandidate(uint candidateID);

    // describes a Voter, which has an id and the ID of the candidate they voted for
    address owner;
    address tokenAddress;
    constructor(address _tokenAddress) {
        owner=msg.sender;
        tokenAddress = _tokenAddress;
    }
    modifier onlyOwner {
        require(msg.sender == owner);

        _;
    }
    struct Voter {
        string uid; // bytes32 type are basically strings
        uint candidateIDVote;
    }
    // describes a Candidate
    struct Candidate {
        string name;
        string party; 
        // "bool doesExist" is to check if this Struct exists
        // This is so we can keep track of the candidates 
        bool doesExist; 
    }

    // These state variables are used keep track of the number of Candidates/Voters 
    // and used to as a way to index them     
    uint numCandidates; // declares a state variable - number Of Candidates
    uint numVoters;

    
    // Think of these as a hash table, with the key as a uint and value of 
    // the struct Candidate/Voter. These mappings will be used in the majority
    // of our transactions/calls
    // These mappings will hold all the candidates and Voters respectively
    mapping (uint => Candidate) candidates;
    mapping (uint => Voter) voters;
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *  These functions perform transactions, editing the mappings *
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function addCandidate(string memory name, string memory party) onlyOwner public {
        // candidateID is the return variable
        uint candidateID = numCandidates++;
        // Create new Candidate Struct with name and saves it to storage.
        candidates[candidateID] = Candidate(name,party,true);
        emit AddedCandidate(candidateID);
    }

    function vote(string calldata uid, uint candidateID, address _voter) external {
        // checks if the struct exists for that candidate
        if (candidates[candidateID].doesExist == true) {
            uint voterID = numVoters+IERC20(tokenAddress).balanceOf(_voter); //voterID is the return variable
            voters[voterID] = Voter(uid,candidateID);
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * 
     *  Getter Functions, marked by the key word "view" *
     * * * * * * * * * * * * * * * * * * * * * * * * * */
    

    // finds the total amount of votes for a specific candidate by looping
    // through voters 
    function totalVotes(uint candidateID) view public returns (uint) {
        uint numOfVotes = 0; // we will return this
        for (uint i = 0; i < numVoters; i++) {
            // if the voter votes for this specific candidate, we increment the number
            if (voters[i].candidateIDVote == candidateID) {
                numOfVotes++;
            }
        }
        return numOfVotes; 
    }

    function getNumOfCandidates() public view returns(uint) {
        return numCandidates;
    }

    function getNumOfVoters() public view returns(uint) {
        return numVoters;
    }
    // returns candidate information, including its ID, name, and party
    function getCandidate(uint  candidateID) public view returns (uint ,string memory, string memory ) {
        return (candidateID,candidates[candidateID].name,candidates[candidateID].party);
    }
}

// deploy votingSource
// deploy erc20 token of dummy contract
// voting contract -> erc20 address
// votingSource -> addConnext
// 