//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    /*****************DATA RELATED CODE****************/
    uint256 private counter;
    address owner;
    //address[] private voted_addresses; 

    //In this version voters array(type of Voter struct) holds voter address and the proposal number 
    struct Voter{
        uint256 proposal_number;
        address voter_address;
    }

    Voter[] private voters;

    constructor() {
        owner = msg.sender;
        voters.push(Voter(0, msg.sender)); //Address of the creater of the ProposalContract is at voters[0].voter_address
    }

    struct Proposal {
        string title; //Title of the proposal
        string description; // Description of the proposal
        uint256 approve; // Number of approve votes
        uint256 reject; // Number of reject votes
        uint256 pass; // Number of pass votes
        uint256 total_vote_to_end; // When the total votes in the proposal reaches this limit, proposal ends
        bool current_state; // This shows the current state of the proposal, meaning whether if passes or fails
        bool is_active; // This shows if others can vote to our contract
    }

    mapping(uint256 => Proposal) proposal_history; // Recordings of previous proposals
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    //If proposal is not active, then voting is stopped.
    modifier active(uint256 number) {
        require(proposal_history[number].is_active == true, "The proposal is not active");
        _;
    }

    //One person can not vote twice for the same proposal 
    modifier newVoter(uint256 number, address _address) {
        require(!isVoted(number, _address), "Address has already voted");
        _;
    }



    /**************EXECUTE FUNCTIONS*****************/
    //Create proposal
    // calldata keyword doesn't let to modify the varible
    function create(string calldata _title, string calldata _description, uint256 _total_vote_to_end) external onlyOwner {
        counter += 1; //Attention here: this will make counter=1, thus proposal_country[0] does not contain any created proposal. 
        proposal_history[counter] = Proposal(_title, _description, 0, 0, 0, _total_vote_to_end, false, true);
        voters.push(Voter(counter, msg.sender));//When proposal is created, whomever created that proposal is added to the voters array

    }

    //To pass ownership of contract to another user
    function setOwner(address new_owner) external onlyOwner {
        owner = new_owner;
    }



    //----------------FOURTH HOMEWORK----------------------//
    //Why I changed the logic of calculateCurrentState() after submitting 4th homework:
    //When I submit 4th homework, isVoted() function was not implemented and I was getting error regarding that. However,
    //everythin else in the code seemed fine. Then after implementing isVoted(), I got compile error about following line:
    // uint reject_weight =-2;
    // since reject_weight is unsigned integer. Then I got similar error in other part of the function as well. Therefore,
    //I decided I will implement new logic, and that is how following code is created.

    //At time of submitting 4th homework, I forgot to push voter to voted_addresses array 
    //when they vote. It is fixed in here, inside vote() function. 

    //Helper function which implements the logic to calculate the state of proposal based on approve, reject and pass votes
    function calculateCurrentState(uint256 number) private view returns(bool) {
        Proposal storage proposal = proposal_history[number];

        uint256 approve = proposal.approve;
        uint256 reject = proposal.reject;
        uint256 pass = proposal.pass;
        uint256 approve_threshold = 60; // it means, if 60% of all votes is approve, then the proposal will be accepted 
        
        uint256 total_votes= approve+reject+pass;

        uint256 approve_percentage = (approve*100)/total_votes; //integer division
        if (approve_percentage >= approve_threshold) {
            return true;
        } else {
            return false;
        }
    }
    //---------------------FOUTRTH HOMEWORK ENDS-----------------//



    //Voting function
    //I made the function more flexible by allowing users to choose whichever 
    //proposal they want to vote, not just the current one. 
    //This change also requiers changes in active(), newVoter() modifiers and in isVoted(), terminateProposal() functions.

    function voteProposal(uint256 number, uint8 choice) external active(number) newVoter(number, msg.sender){
        if(!(0<=choice && choice<3)) revert("You made invalid choice. Valid choices are: 0(for pass), 1(for approve) and 2(for reject).");
        if(number>counter) revert("Invalid proposal number.");
         // First part
        Proposal storage proposal = proposal_history[counter];
        uint256 total_vote = proposal.approve + proposal.reject + proposal.pass;

        //voted_addresses.push(msg.sender);

        voters.push(Voter(number, msg.sender));

        // Second part
        //Since calculateCurrenState() will be executed regardles of the choice,
        //I put it to the outside of the if else statement(makes the code more clean).
        if (choice == 1) {
            proposal.approve += 1;
        } else if (choice == 2) {
            proposal.reject += 1;
        } else if (choice == 0) {
            proposal.pass += 1;
        }

        proposal.current_state = calculateCurrentState(number);

        //Third part
        //Since we check validity of the choice at the beginning of the function, we do not need to check here.
        //Therefore (choice == 1 || choice == 2 || choice == 0) condition is deleted.
        if (proposal.total_vote_to_end - total_vote == 1) {
            proposal.is_active = false;
            //With current version, resetting voters array is not required, 
            //since voter addresses are stored with proposal numbers.
    
            //voted_addresses = [owner]; //Reset voted_addresses array when voting ended
        }
    }


    function teminateProposal(uint256 number) external onlyOwner active(number) {
       proposal_history[number].is_active = false;
    }

    
    //I added fundContract() , to let users to fund the contract
    function fundContract() public payable{
        
     }

    //withdraw() function to transfer currency from the contract to the owner
     function withdraw() public onlyOwner{
       (bool callSuccess, ) = payable (msg.sender).call{value: address(this).balance}("");
       require(callSuccess, "Call failed");
     }


    /******************QUERY FUNCTIONS*******************/
    function isVoted(uint256 number, address _address) public view returns (bool) {
        for (uint i = 0; i < voters.length; i++) {
            if (voters[i].voter_address == _address && voters[i].proposal_number == number) {
                return true;
            }      
        }
        return false;
    }

    function getCurrentProposal() external view returns(Proposal memory) {
        return proposal_history[counter];

    }

    function getProposal(uint256 number) external view returns(Proposal memory) {
        return proposal_history[number];
    }

    
    //I added getOwner() to show current owner of the propsal contract
    function getOwner() external view returns(address){
        return owner;
    }

    function getVoters() external view returns(Voter[] memory){
        return voters;
    }

}
