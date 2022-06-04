//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Interface for the FakeNFTMarketplace
 */
interface IFakeNFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    /// @return Returns the price in Wei for an NFT
    function getPrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

/**
 * Minimal interface for CryptoDevsNFT containing only two functions
 * that we are interested in
 */

interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address, uint256 index)
        external
        view
        returns (uint256 token);
}

contract CryptodevsDAO is Ownable {
    struct Proposal {
        uint256 tokenId;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        uint256 deadline;
        mapping(uint256 => bool) voters;
    }

    enum Vote {
        YAY,
        NAY
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "not a DAO member");
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "deadline exceeded"
        );
        _;
    }

    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline < block.timestamp,
            "deadline not exceeded"
        );
        require(
            proposals[proposalIndex].executed == false,
            "proposal already executed"
        );
        _;
    }

    /**
        @dev createProposal allows a CryptoDevsNFT holder to create a new proposal in the DAO
        @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if this proposal passes
        @return Returns the proposal index for the newly created proposal
     */
    function createProposal(uint256 _nftTokenId)
        external
        nftHolderOnly
        returns (uint256)
    {
        require(
            nftMarketplace.available(_nftTokenId),
            "NFT is not available for sale"
        );

        Proposal storage proposal = proposals[numProposals];
        proposal.tokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;
        return numProposals - 1;
    }

    /**
        @dev function to vote for a proposal
        @param proposalIndex index in the proposals mapping
        @param vote the type of vote YAY or NAY
     */

    function voteOnProposal(uint256 proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "already voted");
        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    /**
    @dev executeProposal allows any CryptoDevsNFT holder to execute a proposal after it's deadline has been exceeded
    @param proposalIndex - the index of the proposal to execute in the proposals array
     */

    function executeProposal(uint256 proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "not enough funds");
            nftMarketplace.purchase{value: nftPrice}(proposal.tokenId);
        }

        proposal.executed = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        address _owner = owner();
        (bool sent, ) = _owner.call{value: balance}("");
        require(sent, "failed to withdraw");
    }

    receive() external payable {}

    fallback() external payable {}
}

// 0xDD19D712A7AdC712E7EE919aCf6cbe23cD7Cb381
