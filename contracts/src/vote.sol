// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./social_graph.sol";
import {ExponentialCalculator} from "./helpers/exponential.sol";

contract Voting is Worldcoin {
    ExponentialCalculator e;
    constructor(address _address) {
        e = ExponentialCalculator(_address);
    }

    function updateStatusVerified(uint x) public isRegistered(msg.sender) {
        uint256 y;
        for (uint i = 0; i < users[msg.sender].recommenders.length; i++) {
            y += users[msg.sender].recommenders[i].weight;
        }
        
        //TODO confirm overflows and verify corner cases like x=0
        uint val = 1 - e.power(y*50);
        uint B = 1 - e.power(x/2);
        require(val>=B && users[msg.sender].status == 2,"Not eligible to update Status");
        users[msg.sender].status = 1;
        users[msg.sender].vhot = val;
        users[msg.sender].vcold = 0;

        for (uint i = 0; i < users[msg.sender].recommenders.length; i++) {
            uint _userID = users[msg.sender].recommenders[i].userID;
            uint _weight = users[msg.sender].recommenders[i].weight;
            address addOfRecommenderCandidate = userAddress[_userID];
            users[addOfRecommenderCandidate].vhot += _weight;
            users[addOfRecommenderCandidate].vcold -= _weight;

            rewards[_userID] += _weight;
        }
    }

    function recommendCandidate(VotingPair[] memory _votes) external canVote(msg.sender) {
        uint sumOfWeights=0;
        // Iterate through the array of votes
        for (uint i = 0; i < _votes.length; i++) {
            // Access each pair (userID, weight)
            uint _userID = _votes[i].userID;
            //exits if even one candidate user ID is invalid
            require(users[userAddress[_userID]].isRegistered, "Candidate not registered");
            uint _weight = _votes[i].weight;
            sumOfWeights+=_weight;
        }

        require(users[msg.sender].vhot >= sumOfWeights, "Do not have enough voting power left");
        users[msg.sender].vhot -= sumOfWeights;
        users[msg.sender].vcold += sumOfWeights;
        
        for (uint i = 0; i < _votes.length; i++) {
            uint _userID = _votes[i].userID;
            uint _weight = _votes[i].weight;
            uint _uidOfSender = users[msg.sender].uid;
            address addOfRecommendedCandidate = userAddress[_userID];

            users[msg.sender].recommendees.push(_votes[i]);
            users[addOfRecommendedCandidate].recommenders.push(VotingPair(_uidOfSender, _weight));
        }  

    }
}