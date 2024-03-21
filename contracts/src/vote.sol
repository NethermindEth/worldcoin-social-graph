// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./social_graph.sol";
import {ExponentialCalculator} from "./helpers/exponential.sol";

contract Voting is Worldcoin {
    ExponentialCalculator e;
    constructor(address _address) {
        e = ExponentialCalculator(_address);
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

    function updateStatusVerified() public isRegistered(msg.sender) {
        // msg.sender should be a candidate
        require(users[msg.sender].status == 2,"Not eligible to update Status");
        uint256 y = 0;
        for (uint i = 0; i < users[msg.sender].recommenders.length; i++) {
            //y stores the total weight received as votes
            y += users[msg.sender].recommenders[i].weight;
        }
        require(y > x, "User should have higher power than threshold");
        //val refers to the voting power a user has
        // val currently has precision of 5 decimals
        uint val = 10**5 - e.inversePower(y/2);
        
        users[msg.sender].status = 1;
        users[msg.sender].vhot = val/10**3;
        users[msg.sender].vcold = 0;

        uint c_epoch = (block.number/50064) + 1;

        for (uint i = 0; i < users[msg.sender].recommenders.length; i++) {
            uint _userID = users[msg.sender].recommenders[i].userID;
            uint _weight = users[msg.sender].recommenders[i].weight;
            address addOfRecommenderCandidate = userAddress[_userID];

            users[addOfRecommenderCandidate].vhot += a * _weight / 100;
            users[addOfRecommenderCandidate].vcold -= _weight;
            
            user_epoch_weights[addOfRecommenderCandidate][c_epoch] += _weight;
            rewards_per_epoch[c_epoch].sum += _weight;
        }
    }

    function getRecommender(uint userID, address _sender) internal view returns (bool isRec, uint pos) {
        // Will loop through recommenders looking for userID
        for (uint i = 0; i < users[_sender].recommenders.length; i++) {
            if (users[_sender].recommenders[i].userID == userID) {
                return (true, i);
            }
        }
        // If no recommender is found, returns false
        return (false, 0);
    }

    function penalise(uint userID) public isRegistered(msg.sender){
        // Check that userID is recommender of sender
        // position of recommender in sender's recommenders lists
        (bool isRec, uint position) = getRecommender(userID, msg.sender);
        require(isRec, "UserID is not a recommender");
        // set t to be weight
        uint t = users[msg.sender].recommenders[position].weight;
        // reduce vhot or vcold of userID
        if (users[msg.sender].status == 1) {
            users[userAddress[userID]].vhot -= a * t / 100;
        } else {
            users[userAddress[userID]].vcold -= t;
            // remove userID from sender's recommender list
            delete users[msg.sender].recommenders[position];
        }
    }

    function claimReward() public isRegistered(msg.sender) {
        uint c_epoch = (block.number/50064) + 1;
        uint l_epoch = users[msg.sender].lepoch;
        for(uint i = l_epoch + 1; i <= c_epoch - 1; i++) {
            // increase totalReward of the sender in users map
            users[msg.sender].totalReward += c*(user_epoch_weights[msg.sender][i]/rewards_per_epoch[i].sum);
            // increase entry claimed in the rewards map for epoch i
            rewards_per_epoch[i].claimed += user_epoch_weights[msg.sender][i];
            if(rewards_per_epoch[i].sum == rewards_per_epoch[i].claimed)
                delete(rewards_per_epoch[i]);
            delete(user_epoch_weights[msg.sender][i]);
        }
        users[msg.sender].lepoch = c_epoch - 1;
    }
}