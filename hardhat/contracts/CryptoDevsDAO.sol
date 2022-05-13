// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IFakeNFTMarketplace {
    // getPrice() returns the price of an NFT from the fakeNFTMarketplace
    // Returns the price in Wei for an NFt
    function getPrice() external view returns (uint);

    // available() returns whether or not the given _tokenId has already been purchased
    // returns a boolean value - true if avaialble, false if not
    function available(uint _tokenId) external view returns (bool);

    // purchase() purchases an NFT from the FakeNFTMarketplace
    function purchase(uint _tokenId) external payable;
}

// Minimal interface for CryptoDevsNFT containing only two functions we are interested in
interface ICryptoDevsNFT{
     /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}


contract CryptoDevsDAO is Ownable {

    struct Proposal {
        // nftTokenId - the tokenID of the NFT to p[urchase from FakeNFTMarketplace if the proposal passes
        uint256 nftTokenId;
        // deadline- the UNIX timestamp until this proposal is active. Proposal can be executed after the deadline has been exceeded
        uint256 deadline;
        // yayVotes - number of votes in favour
        uint256 yayVotes;
        // nayVotes - number of votes against
        uint256 nayVotes;
        // executed - whether or not the proposal has been executed. Cannot be executed before the deadline has been exceeded.
        bool executed;
        // = voters- a mapping of CryptoDevsNFT tokenIDs to booleans indiciating whether that NFT has been already been used to cast a vote or not 
        mapping(uint256 => bool) voters;
    }

    // create mapping ofrom proposal IDs to proposals 
    mapping(uint256 => Proposal) public proposals;
    // number of proposals created
    uint256 public numProposals;


    // Lets initialize the interfaces of FakeNFTMarketplace and CryptoDevsNFT
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    // Create a payable constructor which initializes the contract
    // instances for FakeNFTMarketplace and CryptoDevsNFT
    // The payable allows this constructor to accept an ETH deposit when it is being deployed
    constructor(address _nftMarketplace, address _cryptoDevsNFT) public payable{
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    //Create a modifier that allows only an OWner of the CryptoDevsNFT to call
    modifier nftHolderOnly(){
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "You must own a CryptoDevsNFT to propose or vote a proposal");
        _;
    }

    // Create a function that creates a proposal for the given NFT tokenID
    // @param _nftTokenId - the tokenID of the NFT to propose
    function createProposal(uint _nftTokenId) external nftHolderOnly returns(uint) {
        require(nftMarketplace.available(_nftTokenId), "NFT is not available");

        // with this "Proposal storage proposal", I'm creating an instance of the struct Proposal
        // and with the entire statement, I'm adding proposal to the proposals mapping
        Proposal storage proposal =  proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        // set the proposal's voting deadline to current time + 5minutes
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;

    }

    // Create a modifier which only allows a function to be
    // called if the given proposal's deadline has not been exceeded yet
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    // Create an enum named Vote containing possible options for a vote
    // YAY = 0
    // NAY = 1
    enum Vote {
        YAY, 
        NAY 
    }

    /// @dev voteOnProposal allows a CryptoDevsNFT holder to cast their vote on an active proposal
    /// @param proposalIndex - the index of the proposal to vote on in the proposals array
    /// @param vote - the type of vote they want to cast
    function voteOnProposal(uint256 proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // Calculate how many NFTs are owned by the voter
        // that haven't already been used for voting on this proposal
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    // Create a modifier which only allows a function to be
    // called if the given proposals' deadline HAS been exceeded
    // and if the proposal has not yet been executed
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }



    /// @dev executeProposal executes a proposal if the proposal's deadline has not been exceeded
    /// @param proposalIndex - the index of the proposal to execute in the proposals array
    function executeProposal(uint proposalIndex) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        if(proposal.yayVotes > proposal.nayVotes) {
            uint nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_ETH");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);

        }
        proposal.executed = true;
        
    }

    // We need more functionality, like the
    // Allow the contract owner to withdraw the ETH from the DAO if needed
    // Allow the contract to accept further ETH deposits

    
    /// @dev withdrawEther allows the contract owner (deployer) to withdraw all the ETH from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}




}