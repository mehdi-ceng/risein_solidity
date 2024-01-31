// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    /*****************DATA RELATED CODE****************/
    uint256 private counter;
    address owner;
    address[]  private voted_addresses; //All users who have voted will be added here.

    constructor() {
        owner = msg.sender;
        voted_addresses.push(msg.sender); //Creator of proposal can not vote to the proposal
    }

    struct Proposal {
        string title; //Title of the proposal
        string description; // Description of the proposal
        uint256 approve; // Number of approve votes
        uint256 reject; // Number of reject votes
        uint256 pass; // Number of pass votes
        uint256 total_vote_to_end; // When the total votes in the proposal reaches this limit, proposal ends
        bool current_state; // This shows the current state of the proposal, meaning whether if passes of fails
        bool is_active; // This shows if others can vote to our contract
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    //If proposal is not active, then voting is stopped.
    modifier active() {
        require(proposal_history[counter].is_active == true, "The proposal is not active");
        _;
    }

    //One person can not vote twice.
    modifier newVoter(address _address) {
        require(!isVoted(_address), "Address has already voted");
        _;
    }


    mapping(uint256 => Proposal) proposal_history; // Recordings of previous proposals


    /**************EXECUTE FUNCTIONS*****************/
    //Create proposal
    // calldata keyword doesn't let to modify the varible
    function create(string calldata _title, string calldata _description, uint256 _total_vote_to_end) external onlyOwner {
        counter += 1;
        proposal_history[counter] = Proposal(_title, _description, 0, 0, 0, _total_vote_to_end, false, true);
    }

    //To pass ownership of contract to another user
    function setOwner(address new_owner) external onlyOwner {
        owner = new_owner;
    }



    //----------------FOURTH HOMEWORK----------------------//
    //Helper function which implements the logic to calculate the state of proposal based on approve, reject and pass votes
    function calculateCurrentState() private view returns(bool) {
        Proposal storage proposal = proposal_history[counter];

        uint256 approve = proposal.approve;
        uint256 reject = proposal.reject;
        uint256 pass = proposal.pass;
        uint8 approve_weight = 2;
        uint8 reject_weight = -2;
        uint8 pass_weight = 1;
        
        uint256 total_sum = approve*approve_weight + reject*reject_weight + pass*pass_weight;

        if (total_sum > 0) {
            return true;
        } else {
            return false;
        }
    }
    //---------------------FOUTRTH HOMEWORK ENDS-----------------//


    //Voting function
    function vote(uint8 choice) external active newVoter(msg.sender){
        // First part
        Proposal storage proposal = proposal_history[counter];
        uint256 total_vote = proposal.approve + proposal.reject + proposal.pass;

        // Second part
        if (choice == 1) {
            proposal.approve += 1;
            proposal.current_state = calculateCurrentState();
        } else if (choice == 2) {
            proposal.reject += 1;
            proposal.current_state = calculateCurrentState();
        } else if (choice == 0) {
            proposal.pass += 1;
            proposal.current_state = calculateCurrentState();
        }

        // Third part
        if ((proposal.total_vote_to_end - total_vote == 1) && (choice == 1 || choice == 2 || choice == 0)) {
            proposal.is_active = false;
            voted_addresses = [owner]; //Reset voted_addresses array when voting ended
        }
    }
}
