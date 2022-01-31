// voting.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    mapping(address => Voter) private whitelist;

    mapping(address => Proposal) public voteDetails;

    Proposal[] private proposals;

    uint256 private winningProposalId;

    // Init WorkFlowStatus.
    WorkflowStatus private workFlowStatus;

    /*
     * Init workFLowStatus to lauch voting process.
     */
    function initWorkFlowStatus() public onlyOwner {
        workFlowStatus = WorkflowStatus.RegisteringVoters;
    }

    /*
     * Return the current state of the WorkFlowStatus.
     */
    function getWorkFlowStatus() public view returns (WorkflowStatus) {
        return workFlowStatus;
    }

    /*
     * Register one voter by address.
     * @param account address of the voter
     */
    function register(address account) public onlyOwner {
        require(
            workFlowStatus == WorkflowStatus.RegisteringVoters,
            "Voter registration period is over."
        );
        require(!whitelist[account].isRegistered, "Voter is already registed.");

        whitelist[account] = Voter(true, false, 0);
        emit VoterRegistered(account);
    }

    /*
     * Proposal registration started.
     * emit WorkflowStatusChange event.
     */
    function startProposalRegistration() public onlyOwner {
        require(
            workFlowStatus == WorkflowStatus.RegisteringVoters,
            "Proposal registration can't be started. Check workflowstatus."
        );

        workFlowStatus = WorkflowStatus.ProposalsRegistrationStarted;

        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    /*
     * Register a proposal as a voter.
     * V1 : no proposal register limitation.
     * @param description Description of the proposal.
     * emit ProposalRegistered event.
     */
    function registerProposal(string memory description) public payable {
        require(
            workFlowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposal registration period is over."
        );
        require(
            whitelist[msg.sender].isRegistered,
            "This address isn't registered as voter."
        );

        proposals.push(Proposal(description, 0));

        emit ProposalRegistered(proposals.length - 1);
    }

    /*
     * Proposal registration started.
     * emit WorkflowStatusChange event.
     */
    function endProposalRegistration() public onlyOwner {
        require(
            workFlowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposal registration can't be ended. Check workflowstatus."
        );

        workFlowStatus = WorkflowStatus.ProposalsRegistrationEnded;

        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    /*
     * Voting session started.
     * emit WorkflowStatusChange event.
     */
    function startVotingSession() public onlyOwner {
        require(
            workFlowStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Voting session can't be started. Check workflowstatus."
        );

        workFlowStatus = WorkflowStatus.VotingSessionStarted;

        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    /*
     * Vote for a proposal.
     * @param proposalId index of the proposal.
     * emit Voted event.
     */
    function vote(uint256 proposalId) public payable {
        require(
            workFlowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session is over."
        );
        require(
            whitelist[msg.sender].isRegistered,
            "This address isn't registered as voter."
        );
        require(!whitelist[msg.sender].hasVoted, "Voter has already voted.");
        require(proposalId < proposals.length, "Wrong proposal Id.");

        proposals[proposalId].voteCount++;
        voteDetails[msg.sender] = proposals[proposalId];
        whitelist[msg.sender].hasVoted = true;

        emit Voted(msg.sender, proposalId);
    }

    /*
     * Voting session ended.
     * emit WorkflowStatusChange event.
     */
    function endVotingSession() public onlyOwner {
        require(
            workFlowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session can't be ended. Check workflowStatus."
        );

        workFlowStatus = WorkflowStatus.VotingSessionEnded;

        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    /*
     * Count proposal vote.
     */
    function countVote() public onlyOwner {
        require(
            workFlowStatus == WorkflowStatus.VotingSessionEnded,
            "Voting session isn't ended."
        );

        uint256 winningProposal = 0;

        for (uint256 index = 0; index < proposals.length - 1; index++) {
            if (
                proposals[index].voteCount >
                proposals[winningProposal].voteCount
            ) {
                winningProposal = index;
            }
        }

        winningProposalId = winningProposal;
    }

    /*
     * Vote tallied.
     * emit WorkflowStatusChange event.
     */
    function voteTallied() public onlyOwner {
        require(
            workFlowStatus == WorkflowStatus.VotingSessionEnded,
            "Vote can't be tallied yet. Check workflowStatus."
        );

        workFlowStatus = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
    }

    /*
     * Return the winning proposal infos.
     */
    function getWinner() public view returns (Proposal memory) {
        require(
            workFlowStatus == WorkflowStatus.VotesTallied,
            "Winner can't be checked now. Votes aren't tallied yet."
        );
        return proposals[winningProposalId];
    }
}
