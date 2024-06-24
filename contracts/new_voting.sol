// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Owned {
	event NewOwner(address indexed old, address indexed current);

	address public owner = msg.sender;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function setOwner(address _new)
		external
		onlyOwner
	{
		emit NewOwner(owner, _new);
		owner = _new;
	}
}

contract Voting is Owned {
    // Declare a complex type to reresent a single voter.

    struct Vote {        
        bool voted;  // if true, that person already voted
        uint256 vote;   // index of the voted proposal
    }

    struct Voter {        
        address addr;
        bool rightToVote; // if true, that person has right to vote
        uint256 weight;      // defines the weightage of voter
        mapping (uint256 => Vote) votes;
    }

    // This is a type for a single proposal.
    struct ProposalOption
    {
        bytes32 name;   // short name for option
        uint256 voteCount; // number of accumulated votes
    }

    // This is a type for a single proposal.
    struct Proposal
    {
        string name;   // short name for proposal
        uint256 votingStart;
        uint256 votingTime;
        uint256 proposalBatch;
        uint256 numOptions;
        uint256 numCastedVotes;
        bool isEnded;
        mapping (uint256 => ProposalOption) proposalOptions;
        uint256 winningProposalOption;
        bytes32 winningProposalOptionName;
    }

    
    address public chairperson;    
    mapping(address => Voter) public voters;
    mapping(uint256 => address) public totalvoters;

    mapping (uint256 => Proposal) public proposals;
    uint256 public numProposals;
    uint256 public numVoters;
    uint256 public numEndedProposals;
    event Voted (address voter, uint256 proposal, uint256 proposalOption);
    event ProposalEnded (uint256 proposal, uint256 winningProposalOption);
    //uint public numProposalOptions;


    constructor()  {
        chairperson = msg.sender;
        numVoters=1;
        totalvoters[numVoters]=msg.sender;
        Voter storage v = voters[msg.sender];
        v.addr=chairperson;
        v.rightToVote = true;
        v.weight = 100;
        numProposals=0;
        numEndedProposals=0;
    }

    function getVotingTime(uint votingTime) public view returns (uint256 time){
        uint256 votingStart = block.timestamp;
        time = votingStart + votingTime;
    }

    function changeChairman(address newAddress) public onlyOwner {
        chairperson = newAddress;
    }

    function changeVoterWeight(address voterAddress,uint256 newWeight) public  {
         require(
            msg.sender == chairperson,
            "Only chairperson can change voting weight"
        ); 
        Voter storage voterDetails = voters[voterAddress];
        voterDetails.weight = newWeight;
    }

    function createProposal(string memory proposalName, bytes32[] memory optionNames, uint256 votingTime, uint256 proposalBatchNumber) public {  
         require(
            msg.sender == chairperson,
            "Only chairperson can create Proposal"
        );   

        numProposals=numProposals+1;
        Proposal storage p = proposals[numProposals]; 
        p.name = proposalName;
        p.numOptions=0;
        p.isEnded=false;
        p.votingStart = block.timestamp;
        p.votingTime = votingTime;
        p.proposalBatch = proposalBatchNumber;
        p.winningProposalOption=99999;
        p.numCastedVotes=0;

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        //numProposalOptions=numProposalOptions+1;
        for (uint256 i = 0; i < optionNames.length; i++) {
            p.proposalOptions[i].name=optionNames[i];
            p.proposalOptions[i].voteCount=0;
            p.numOptions=p.numOptions+1;
        }
    }


    function giveRightToVoteFounder(address voterAddress) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give rights"
        );

        if(voters[voterAddress].addr == voterAddress){
             revert("Voter already exists"); //voter already exists
        }

        numVoters=numVoters+1;   
        totalvoters[numVoters]=voterAddress;     
        Voter storage v = voters[voterAddress];
        v.addr=voterAddress;
        v.rightToVote = true;
        v.weight = 100;
    }

    function giveRightToVoteMember(address voterAddress) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give rights"
        );

       if(voters[voterAddress].addr == voterAddress){
            revert("Voter already exists"); //voter already exists
        }

        numVoters=numVoters+1;
        totalvoters[numVoters]=voterAddress;     
        Voter storage v = voters[voterAddress];
        v.addr=voterAddress;
        v.rightToVote = true;
        v.weight = 0;
    }

    function revokeRightToVote(address voterAddress) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can revoke rights"
        );

        for (uint256 i=1; i<=numVoters;i++){
            if (totalvoters[i] == voterAddress){
               delete totalvoters[i];
               numVoters = numVoters - 1;
           }
        }
        delete voters[voterAddress];
    }

    function vote(uint256 proposal, uint256 proposalOption) public {
        require(block.timestamp < proposals[proposal].votingStart + proposals[proposal].votingTime , "Voting has Ended");
      
        Voter storage sender = voters[msg.sender];

        if (sender.votes[proposal].voted==true){
            revert("User already Voted");
        }

        if (sender.rightToVote==false){
            revert("User do not have right to vote");
        }

        sender.votes[proposal].voted = true;
        sender.votes[proposal].vote = proposalOption;
        proposals[proposal].proposalOptions[proposalOption].voteCount += sender.weight;
        proposals[proposal].numCastedVotes +=1;
        emit Voted (sender.addr, proposal, proposalOption);
        
    }

    function hasUserVoted(uint256 proposal, address user) public view 
            returns (bool result)
    {        
        Voter storage sender = voters[user];

        result=sender.votes[proposal].voted;            
    }

    function getVoterDetail(address user) public view
            returns (bool result, uint256 weight)
    {   
        Voter storage sender = voters[user];
        result=sender.rightToVote;            
        weight=sender.weight;            
    }

    function finalizeProposal(uint256 proposal) public
            returns (string memory proposalName, uint256 winningProposalOption, bytes32 winningProposalOptionName)
        {
        require(
            msg.sender == chairperson,
            "Only chairperson can finalize Proposal"
        );
        
        if (block.timestamp <= proposals[proposal].votingStart + proposals[proposal].votingTime){
            revert("voting did not end yet"); // voting did not yet end
        }
        if (proposals[proposal].isEnded == true){
            revert("The proposal has already ended and cannot be refinalized");
        }
        uint256 winningVoteCount = 0;
        uint256 numProposalOptions=proposals[proposal].numOptions;
        
        for (uint256 i = 0; i < numProposalOptions; i++) {
            if (proposals[proposal].proposalOptions[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[proposal].proposalOptions[i].voteCount;
                winningProposalOption = i;
                //proposalName = proposals[proposal].name;
                //winningProposalOptionName=proposals[proposal].proposalOptions[i].name;
            }
        }

        proposals[proposal].winningProposalOption=winningProposalOption;
        winningProposalOptionName=proposals[proposal].proposalOptions[winningProposalOption].name;
        proposalName = proposals[proposal].name;
        proposals[proposal].winningProposalOptionName=winningProposalOptionName;
        proposals[proposal].isEnded=true;
        numEndedProposals=numEndedProposals+1;
        emit ProposalEnded(proposal, winningProposalOption);

        uint256 proposalsInBatch = 0;
        for (uint256 j=0; j<=numProposals;j++){
            if (proposals[proposal].proposalBatch == proposals[j].proposalBatch) {
                proposalsInBatch += 1;
            }
        }
        //uint precision = 0; //precision is how many decimal places to round, currently it is set to only whole numbers
        uint256 dynamicVoterWeight = uint256(100)*(10**0) / proposalsInBatch; //Calculates a dynamic voting weight based on the total amount of proposals in a batch.
        
        for (uint256 i=1; i<=numVoters;i++){
            
            Voter storage voter = voters[totalvoters[i]];
            
            if(voter.votes[proposal].voted == true){
                //Increase weight by amount of total proposals in a batch dependent on a successful vote
                if (voter.weight < 400){
                    voter.weight = voter.weight+dynamicVoterWeight;
                    if (voter.weight > 400) {
                        uint256 voterExceed = voter.weight - 400;
                        voter.weight = voter.weight - voterExceed;
                    }
                }
            }else{
                //Decrease weight by amount of total proposals in a batch dependent on a successful vote
                if (voter.weight > 100){
                    voter.weight = voter.weight-dynamicVoterWeight;
                    if (voter.weight < 100) {
                        uint256 voterUnder = 100 - voter.weight;
                        voter.weight = voter.weight + voterUnder;
                    }
                }
                    
            }
        }
    }

    function getProposalResult(uint256 proposal) public view
            returns (string memory proposalName, uint256 winningProposalOption, bytes32 winningProposalOptionName, uint256 proposalBatchNumber)
    {
        if(proposals[proposal].isEnded){
            proposalName = proposals[proposal].name;
            proposalBatchNumber = proposals[proposal].proposalBatch;
            winningProposalOption=proposals[proposal].winningProposalOption;
            winningProposalOptionName=proposals[proposal].proposalOptions[winningProposalOption].name;
        }
        else{
            if (block.timestamp <= proposals[proposal].votingStart + proposals[proposal].votingTime){
                revert("voting did not yet end"); // voting did not yet end
            }

            uint256 winningVoteCount = 0;
            uint256 numProposalOptions=proposals[proposal].numOptions;
            
            for (uint256 i = 0; i < numProposalOptions; i++) {
                if (proposals[proposal].proposalOptions[i].voteCount > winningVoteCount) {
                    winningVoteCount = proposals[proposal].proposalOptions[i].voteCount;
                    winningProposalOption = i;
                    //winningProposalOptionName=proposals[proposal].proposalOptions[i].name;
                }
            }
            proposalName = proposals[proposal].name;
            winningProposalOptionName=proposals[proposal].proposalOptions[winningProposalOption].name;
        }
    }
    

    function getProposalDetailsForVoter(uint256 proposal, address user) public view
            returns (string memory proposalName, uint256 numOptions, bytes32[] memory optionNames )
    {       
        if (block.timestamp <= proposals[proposal].votingStart + proposals[proposal].votingTime){// voting did not yet end            
           
            Voter storage sender = voters[user];
            //result=sender.votes[proposal].voted;
            if(sender.votes[proposal].voted==false){ //user hasn't voted for this proposal
                proposalName = proposals[proposal].name;     
                numOptions = proposals[proposal].numOptions;
                optionNames=new bytes32[](numOptions);
                for (uint256 i = 0; i < proposals[proposal].numOptions; i++) {
                    optionNames[i]=proposals[proposal].proposalOptions[i].name;
                }
            }
        }
    }

    function getProposalOptionName(uint256 proposal, uint256 proposalOptionNum) public view
            returns (bytes32 proposalOptionName)
    {               
        proposalOptionName = proposals[proposal].proposalOptions[proposalOptionNum].name;        
    }


}

