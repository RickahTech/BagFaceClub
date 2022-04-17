// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/** 
BagFace DAO Contract:
1: Collects investors money (ether) and allocate shares
2: Keeps Track of investors contributions with shares
3: Allow Investors to transfer shares
4: Allow investment proposal to be created and voted
5: Execute successful investment proposales (i.e send money)
*/

contract DAO {
    struct Proposal{
        uint id;
        string name;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool executed;
    }
    mapping(address => bool) public investors;
    mapping(address => uint) public shares;
    mapping(address => mapping(uint => bool)) public votes;
    mapping(uint => Proposal) public proposals;
    uint public totalShares;
    uint public availableFunds;
    uint public contributionEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public admin;

    constructor(
        uint contributionTime,
        uint _voteTime,
        uint _quorum)
        public {
        require(_quorum >0 && _quorum < 100, 'Quorum must be between 0 and 100');
        contributionEnd = block.timestamp + contributionTime;
        voteTime = _voteTime;
        quorum = _quorum;
        admin = msg.sender;
        }

        function contribute() payable external {
            require(block.timestamp < contributionEnd, 'Cant contribute after contributionEnd' );
            investors[msg.sender] = true;
            shares[msg.sender] += msg.value;
            totalShares += msg.value;
            availableFunds += msg.value;
        }
        
        function redeemShare() public payable returns (uint amount){
            require(shares[msg.sender] >= amount, 'Not enough shares');
            require(availableFunds >= amount, 'Not enough funds');
            shares[msg.sender] -= amount;
            availableFunds -= amount;
            payable(msg.sender).transfer(amount);
        } 

    



        function transferShare(uint amount, address to) external {
            require(shares[msg.sender] >= amount, 'Not enough shares');
            shares[msg.sender] -= amount;
            shares[to] += amount;
            investors[to] = true;
        }

        function createProposal(
            string memory name,
            uint amount, 
            address payable recipient)
            public
            onlyInvestors() {
            require(availableFunds >= amount, 'Amount too big');
            proposals[nextProposalId] = Proposal(
                nextProposalId,
                name,
                amount,
                recipient,
                0,
                block.timestamp + voteTime,
                false
            );
            availableFunds -= amount;
            nextProposalId++;
        }
        
        function vote(uint proposalId) external onlyInvestors(){
            Proposal storage proposal = proposals[proposalId];
            require(votes[msg.sender][proposalId] = false, 'investors can only vote once for proposal');
            require(block.timestamp < proposal.end, 'can only vote until proposal end date');
            votes[msg.sender][proposalId] = true;
            proposal.votes += shares[msg.sender];
            }
        function executeProposal(uint proposalId) external onlyAdmin(){
            Proposal storage proposal = proposals[proposalId];
            require(block.timestamp >= proposal.end , 'cannot execute proposal before end date');
            require(proposal.executed == false, 'cannot execute proposal already executed');
            require((proposal.votes / totalShares) * 100 >= quorum, 'cannot execute proposal with votes # below quorum');
            _transferEther(proposal.amount, proposal.recipient);

        }
        function withdrawEther(uint amount, address payable to) external onlyAdmin() {
            _transferEther(amount, to);
        }

        function _transferEther(uint amount, address payable to) internal {
            require(amount <= availableFunds, 'not enough availableFunds');
            availableFunds -= amount;
            to.transfer(amount);
        }

        // For Ether returns of proposal investments
        fallback() payable external {
            availableFunds += msg.value;
        }

        modifier onlyInvestors() {
            require(investors[msg.sender] == true, 'only investors');
            _;
        }

        modifier onlyAdmin() {
            require(msg.sender == admin, 'only admin');
            _;
        }


}
