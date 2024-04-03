// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import { Worldcoin } from "./social_graph.sol";
import { Contract } from "./Contract.sol";
import "../../lib/abdk-libraries-solidity/ABDKMath64x64.sol";

contract Voting is Worldcoin {
    function inversePower(uint256 x) public pure returns (uint) {
        // Represent the percentage as a fixed-point number.
        int128 percentage = ABDKMath64x64.divu(x, 100);

        // Calculate e^(percentage)
        int128 result = ABDKMath64x64.exp(percentage);

        // Multiply by 10^5 to keep 5 decimal places
        result = ABDKMath64x64.mul(result, ABDKMath64x64.fromUInt(10**5));

        // Invert the exponential as required
        result = ABDKMath64x64.div(ABDKMath64x64.fromUInt(10**5), result); 

        // Multiply by 10^5 to keep 5 decimal places
        result = ABDKMath64x64.mul(result, ABDKMath64x64.fromUInt(10**5));

        // Convert the fixed-point result to a uint and return it.
        return ABDKMath64x64.toUInt(result);
    }

    // Function to register an account as a World ID holder
    function registerAsWorldIDHolder(
        uint _worldID,
        string calldata _name,
        Contract _contract,
        address signal, 
        uint256 root, 
        uint256 nullifierHash, 
        uint256[8] calldata proof
        ) public {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // Perform checks to verify World ID
        _contract.verifyAndExecute(signal, root, nullifierHash, proof);
        // checks if world ID is already registered
        require(!worldIDs[_worldID], "This World ID is already registered");
        worldIDs[_worldID] = true;
        // compute current epoch
        uint c_epoch = (block.number/50064) + 1;
        // add new user to user map
        users[msg.sender] = User(id, _name, true, true, _worldID, 100, 0, 0, 0, c_epoch - 1);
        user_epoch_weights[msg.sender][c_epoch] = 0;
        userAddress[id++] = msg.sender;
    }
    
    // Function to register an account as a Candidate
    function registerAsCandidate(string calldata _name) external {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // compute current epoch
        uint c_epoch = (block.number/50064) + 1;
        // add user to user map
        users[msg.sender] = User(id, _name, false, true, 0, 0, 0, 2, 0, c_epoch - 1);
        userAddress[id++] = msg.sender;
    }

    //Function to vote for a candidate
    function recommendCandidate(VotingPair[] memory _votes) external canVote(msg.sender) {
        uint sumOfWeights=0;
        // Iterate through the array of votes
        for (uint i = 0; i < _votes.length; i++) {
            // Access each pair (userID, weight)
            uint _userID = _votes[i].userID;
            //exits if even one candidate user ID is invalid
            require(users[userAddress[_userID]].isRegistered, "Candidate not registered");
            require(users[userAddress[_userID]].status == 2, "You can only vote for a candidate");
            uint _weight = _votes[i].weight;
            sumOfWeights+=_weight;
        }

        //Checks if voter has enough voting power left to vote
        require(users[msg.sender].vhot >= sumOfWeights, "Do not have enough voting power left");
        users[msg.sender].vhot -= sumOfWeights;
        users[msg.sender].vcold += sumOfWeights;
        
        for (uint i = 0; i < _votes.length; i++) {
            uint _userID = _votes[i].userID;
            uint _weight = _votes[i].weight;
            uint _uidOfSender = users[msg.sender].uid;
            address addOfRecommendedCandidate = userAddress[_userID];

            recommendees[msg.sender].push(_votes[i]);
            recommenders[addOfRecommendedCandidate].push(VotingPair(_uidOfSender, _weight));
        }  
    }

    //Function called by candidate to update his/her status
    function updateStatusVerified() public isRegistered(msg.sender) {
        // msg.sender should be a candidate
        require(users[msg.sender].status == 2,"Not eligible to update Status");
        uint256 y = 0;
        for (uint i = 0; i < recommenders[msg.sender].length; i++) {
            //y stores the total weight received as votes
            y += recommenders[msg.sender][i].weight;
        }
        require(y > x, "User should have higher power than threshold");
        //val refers to the voting power a user has
        // val currently has precision of 5 decimals
        uint val = 10**5 - inversePower(y/2);
        
        users[msg.sender].status = 1;
        users[msg.sender].vhot = val/10**3;
        users[msg.sender].vcold = 0;

        uint c_epoch = (block.number/50064) + 1;

        for (uint i = 0; i < recommenders[msg.sender].length; i++) {
            uint _userID = recommenders[msg.sender][i].userID;
            uint _weight = recommenders[msg.sender][i].weight;
            address addOfRecommenderCandidate = userAddress[_userID];

            users[addOfRecommenderCandidate].vhot += (a * _weight) / 100;
            users[addOfRecommenderCandidate].vcold -= _weight;
            
            user_epoch_weights[addOfRecommenderCandidate][c_epoch] += _weight;
            rewards_per_epoch[c_epoch].sum += _weight;
        }
    }

    //Function to return information about a particular recommender
    function getRecommender(uint userID, address _sender) internal view returns (bool isRec, uint pos) {
        // Will loop through recommenders looking for userID
        for (uint i = 0; i < recommenders[_sender].length; i++) {
            if (recommenders[_sender][i].userID == userID) {
                return (true, i);
            }
        }
        // If no recommender is found, returns false
        return (false, 0);
    }

    //Function called by candidates to penalise their recommenders
    function penalise(uint userID) public isRegistered(msg.sender){
        require(users[msg.sender].status == 2, "must be candidate");
        // Check that userID is recommender of sender
        // position of recommender in sender's recommenders lists
        (bool isRec, uint position) = getRecommender(userID, msg.sender);
        require(isRec, "UserID is not a recommender");
        // set t to be weight
        uint t = recommenders[msg.sender][position].weight;
        // reduce vcold of userID
        users[userAddress[userID]].vcold -= t;
        // remove userID from sender's recommender list
        delete recommenders[msg.sender][position];
    }

    //Function called by verified identities/WorldID holders to claim rewards after voting
    function claimReward() public isRegistered(msg.sender) {
        uint c_epoch = (block.number/50064) + 1;
        uint l_epoch = users[msg.sender].lepoch;
        for(uint i = l_epoch + 1; i <= c_epoch - 1; i++) {
            // increase totalReward of the sender in users map
            users[msg.sender].totalReward += c*(user_epoch_weights[msg.sender][i]/rewards_per_epoch[i].sum);
            // increase entry claimed in the rewards map for epoch i
            rewards_per_epoch[i].claimed += user_epoch_weights[msg.sender][i];
            if(rewards_per_epoch[i].sum == rewards_per_epoch[i].claimed) {
                delete(rewards_per_epoch[i]);
            }
            delete(user_epoch_weights[msg.sender][i]);
        }
        users[msg.sender].lepoch = c_epoch - 1;
    }

}