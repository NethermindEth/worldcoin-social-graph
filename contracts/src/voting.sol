// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Worldcoin} from "./social_graph.sol";
import {verifyWorldID} from "./verifyWorldID.sol";
import "../lib/abdk-libraries-solidity/ABDKMath64x64.sol";

contract Voting is Worldcoin {
    verifyWorldID worldIDContract;

    constructor(verifyWorldID _worldIDContract) {
        worldIDContract = _worldIDContract;
    }

    function inversePower(uint256 input) public pure returns (uint256) {
        // Represent the percentage as a fixed-point number.
        int128 percentage = ABDKMath64x64.divu(input, 100);

        // Calculate e^(percentage)
        int128 result = ABDKMath64x64.exp(percentage);

        // Multiply by 10^5 to keep 5 decimal places
        result = ABDKMath64x64.mul(result, ABDKMath64x64.fromUInt(10 ** 5));

        // Invert the exponential as required
        result = ABDKMath64x64.div(ABDKMath64x64.fromUInt(10 ** 5), result);

        // Multiply by 10^5 to keep 5 decimal places
        result = ABDKMath64x64.mul(result, ABDKMath64x64.fromUInt(10 ** 5));

        // Convert the fixed-point result to a uint and return it.
        return ABDKMath64x64.toUInt(result);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function calculateCurrentEpoch() internal view returns (uint256) {
        return (block.number / 50064) + 1;
    }

    // Function to register an account as a World ID holder
    function registerAsWorldIDHolder(
        string calldata _name,
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // Perform checks to verify World ID
        worldIDContract.verifyAndExecute(signal, root, nullifierHash, proof);
        // compute current epoch
        uint256 c_epoch = calculateCurrentEpoch();
        // add new user to user map
        users[msg.sender] = User(_name, true, true, 100, 0, Status.WorldIDHolder, 0, c_epoch - 1);
        user_epoch_weights[msg.sender][c_epoch] = 0;
        userAddress[id++] = msg.sender;
    }

    // Function to register an account as a Candidate
    function registerAsCandidate(string calldata _name) external {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // compute current epoch
        uint256 c_epoch = calculateCurrentEpoch();
        // add user to user map
        users[msg.sender] = User(_name, false, true, 0, 0, Status.Candidate, 0, c_epoch - 1);
        userAddress[id++] = msg.sender;
    }

    //Function to vote for a candidate
    function recommendCandidate(VotingPair[] memory _votes) external canVote(msg.sender) {
        uint256 sumOfWeights = 0;
        // Iterate through the array of votes
        for (uint256 i = 0; i < _votes.length; i++) {
            // Access each pair (userID, weight)
            uint256 _userID = _votes[i].userID;
            //exits if even one candidate user ID is invalid
            require(users[userAddress[_userID]].isRegistered, "Candidate not registered");
            require(users[userAddress[_userID]].status == Status.Candidate, "You can only vote for a candidate");
            uint256 _weight = _votes[i].weight;
            sumOfWeights += _weight;
        }

        //Checks if voter has enough voting power left to vote
        require(users[msg.sender].vhot >= sumOfWeights, "Do not have enough voting power left");
        users[msg.sender].vhot -= sumOfWeights;
        users[msg.sender].vcold += sumOfWeights;

        for (uint256 i = 0; i < _votes.length; i++) {
            uint256 _userID = _votes[i].userID;
            uint256 _weight = _votes[i].weight;
            uint256 _uidOfSender = users[msg.sender].uid;
            address addOfRecommendedCandidate = userAddress[_userID];
            recommendees[msg.sender].push(_votes[i]);
            recommenders[addOfRecommendedCandidate].push(VotingPair(_uidOfSender, _weight));
        }
    }

    //Function called by candidate to update his/her status
    function updateStatusVerified() public isRegistered(msg.sender) {
        // msg.sender should be a candidate
        require(users[msg.sender].status == Status.Candidate, "Not eligible to update Status");
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < recommenders[msg.sender].length; i++) {
            //stores the total weight received as votes
            totalWeight += recommenders[msg.sender][i].weight;
        }
        require(totalWeight > x, "User should have higher power than threshold");
        //val refers to the voting power a user has
        //val currently has precision of 5 decimals
        uint256 val = 10 ** 5 - inversePower(totalWeight / 2);

        users[msg.sender].status = Status.VerifiedIdentity;
        users[msg.sender].vhot = val / 10 ** 3;

        uint256 c_epoch = calculateCurrentEpoch();

        for (uint256 i = 0; i < recommenders[msg.sender].length; i++) {
            uint256 _userID = recommenders[msg.sender][i].userID;
            uint256 _weight = recommenders[msg.sender][i].weight;
            address addOfRecommenderCandidate = userAddress[_userID];

            users[addOfRecommenderCandidate].vhot += (a * _weight) / 100;
            users[addOfRecommenderCandidate].vcold -= _weight;

            user_epoch_weights[addOfRecommenderCandidate][c_epoch] += _weight;
            rewards_per_epoch[c_epoch] += _weight;
        }
    }

    //Function to return information about a particular recommender
    function getRecommenderPosition(uint256 userID, address _sender) internal view returns (bool isRec, uint256 pos) {
        // Will loop through recommenders looking for userID
        for (uint256 i = 0; i < recommenders[_sender].length; i++) {
            if (recommenders[_sender][i].userID == userID) {
                return (true, i);
            }
        }
        // If no recommender is found, returns false
        return (false, 0);
    }

    //Function to return information about a particular recommendee
    function getRecommendeePosition(uint256 userID, address _sender) internal view returns (bool isRec, uint256 pos) {
        // Will loop through recommenders looking for userID
        for (uint256 i = 0; i < recommendees[userAddress[userID]].length; i++) {
            if (recommendees[userAddress[userID]][i].userID == userID) {
                return (true, i);
            }
        }
        // If no recommender is found, returns false
        return (false, 0);
    }

    //Function called by candidates to penalise their recommenders
    function penalise(uint256 userID) public isRegistered(msg.sender) {
        require(users[msg.sender].status == Status.Candidate, "User must be candidate");
        // Check that userID is recommender of sender
        // position of recommender in sender's recommenders lists
        (bool isRecommender, uint256 position1) = getRecommenderPosition(userID, msg.sender);
        (bool isRecommendee, uint256 position2) = getRecommendeePosition(userID, msg.sender);
        require(isRecommender, "UserID is not a recommender");
        // set t to be weight
        uint256 t = recommenders[msg.sender][position1].weight;
        // reduce vcold of userID
        users[userAddress[userID]].vcold -= t;
        // remove userID from sender's recommender(users who vote for you) and recommendee(users who you vote for) list
        delete recommenders[msg.sender][position1];
        delete recommendees[userAddress[userID]][position2];
    }

    //Function called by verified identities/WorldID holders to claim rewards after voting
    function claimReward(uint256[] memory epochs) public isRegistered(msg.sender) {
        uint256 c_epoch = calculateCurrentEpoch();
        for (uint256 i = 0; i < epochs.length; i++) {
            if (epochs[i] < c_epoch) {
                // increase totalReward of the sender in users map
                users[msg.sender].totalReward +=
                    c * (user_epoch_weights[msg.sender][epochs[i]] / rewards_per_epoch[epochs[i]]);
                delete user_epoch_weights[msg.sender][epochs[i]];
            }
        }
    }

    function getListOfRecommenders(uint256 _userID) public view returns (VotingPair[] memory) {
        return recommenders[userAddress[_userID]];
    }

    function getListOfRecommendees(uint256 _userID) public view returns (VotingPair[] memory) {
        return recommendees[userAddress[_userID]];
    }
}
