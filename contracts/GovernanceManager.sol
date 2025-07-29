// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract GovernanceManager is AccessControl {
    
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    
    struct Proposal {
        uint256 proposalId;
        string title;
        string description;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public nextProposalId = 1;
    uint256 public votingPeriod = 7 days;
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 timestamp);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 timestamp);
    event ProposalExecuted(uint256 indexed proposalId, uint256 timestamp);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PROPOSER_ROLE, msg.sender);
    }
    
    function createProposal(
        string memory _title,
        string memory _description
    ) external onlyRole(PROPOSER_ROLE) returns (uint256) {
        uint256 proposalId = nextProposalId++;
        
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + votingPeriod,
            executed: false
        });
        
        emit ProposalCreated(proposalId, msg.sender, _title, block.timestamp);
        return proposalId;
    }
    
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(block.timestamp < proposal.deadline, "Voting period ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");
        
        hasVoted[_proposalId][msg.sender] = true;
        
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, block.timestamp);
    }
    
    function executeProposal(uint256 _proposalId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved");
        
        proposal.executed = true;
        
        emit ProposalExecuted(_proposalId, block.timestamp);
    }
    
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        require(proposals[_proposalId].proposalId != 0, "Proposal does not exist");
        return proposals[_proposalId];
    }
    
    function setVotingPeriod(uint256 _newPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        votingPeriod = _newPeriod;
    }
}
