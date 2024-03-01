// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./social_graph.sol";
import {ExponentialCalculator} from "./helpers/exponential.sol";

contract Voting is Worldcoin {
    ExponentialCalculator e;
    constructor(address _address) {
        e = ExponentialCalculator(_address);
    }

    function assignStatus(uint val) internal pure returns(uint) {
        //0 - World ID identities, 1 - Derived identities, 2 - Ascendants, 3 - Rejected
        if(val>=1)
            return 1;
        else if(val<0)
            return 3;
        else return 2;
    }

    function recommendCandidate(VotingPair[] memory _votes) external canVote(msg.sender) {
        uint sumOfWeights=0;
        // Iterate through the array of votes
        for (uint i = 0; i < _votes.length; i++) {
            // Access each pair (userID, weight)
            uint _userID = _votes[i].userID;
            //TODO - exits if even one candidate wrong
            require(users[userAddress[_userID]].isRegistered, "Candidate not registered");
            uint _weight = _votes[i].weight;
            sumOfWeights+=_weight;
        }

        require(users[msg.sender].vhot >= sumOfWeights, "Donot have enough voting power left");
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