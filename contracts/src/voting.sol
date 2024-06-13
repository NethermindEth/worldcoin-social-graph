// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Worldcoin} from "./social_graph.sol";
import {verifyWorldID} from "./verifyWorldID.sol";
import "../lib/abdk-libraries-solidity/ABDKMath64x64.sol";

contract Voting is Worldcoin {
    // verifyWorldID worldIDContract;

    // constructor(verifyWorldID _worldIDContract) {
    //     worldIDContract = _worldIDContract;
    // }

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
        string calldata _name
        // string calldata _name,
        // address signal,
        // uint256 root,
        // uint256 nullifierHash,
        // uint256[8] calldata proof
    ) public {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // Perform checks to verify World ID
        // worldIDContract.verifyAndExecute(signal, root, nullifierHash, proof);
        // compute current epoch
        uint256 c_epoch = calculateCurrentEpoch();
        // add new user to user map
        users[msg.sender] = User(_name, true, true, 100, 0, Status.WorldIDHolder, 0, c_epoch - 1);
        user_epoch_weights[msg.sender][c_epoch] = 0;
    }

    // Function to register an account as a Candidate
    function registerAsCandidate(string calldata _name) external {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // compute current epoch
        uint256 c_epoch = calculateCurrentEpoch();
        // add user to user map
        users[msg.sender] = User(_name, false, true, 0, 0, Status.Candidate, 0, c_epoch - 1);
    }

    //Function to vote for a candidate
    function recommendCandidate(VotingPair[] memory _votes) external canVote(msg.sender) {
        uint256 sumOfWeights = 0;
        // Iterate through the array of votes
        for (uint256 i = 0; i < _votes.length; i++) {
            // Access each pair (userAddress, weight)
            address _userAddress = _votes[i].userAddress;
            //exits if even one candidate userAddress is invalid
            require(users[_userAddress].isRegistered, "Candidate not registered");
            require(users[_userAddress].status == Status.Candidate, "You can only vote for a candidate");
            _votes[i].weight = min(1000 - assignedWeight[_userAddress], _votes[i].weight);
            uint256 _weight = _votes[i].weight;
            sumOfWeights += _weight;
            assignedWeight[_userAddress] += _weight;
        }

        //Checks if voter has enough voting power left to vote
        require(users[msg.sender].vhot >= sumOfWeights, "Do not have enough voting power left");
        users[msg.sender].vhot -= sumOfWeights;
        users[msg.sender].vcold += sumOfWeights;

        for (uint256 i = 0; i < _votes.length; i++) {
            address addOfRecommendedCandidate = _votes[i].userAddress;
            uint256 _weight = _votes[i].weight;
            recommendees[msg.sender].push(_votes[i]);
            recommenders[addOfRecommendedCandidate].push(VotingPair(msg.sender, _weight));
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
            uint256 _weight = recommenders[msg.sender][i].weight;
            address addressOfRecommender = recommenders[msg.sender][i].userAddress;

            users[addressOfRecommender].vhot += (a * _weight) / 100;
            users[addressOfRecommender].vcold -= _weight;

            user_epoch_weights[addressOfRecommender][c_epoch] += _weight;
            rewards_per_epoch[c_epoch] += _weight;
        }
    }

    //Function to return information about a particular recommender
    function getRecommenderPosition(address _userAddress, address _sender)
        internal
        view
        returns (bool isRec, uint256 pos)
    {
        // Will loop through recommenders searching for a particular user
        for (uint256 i = 0; i < recommenders[_sender].length; i++) {
            if (recommenders[_sender][i].userAddress == _userAddress) {
                return (true, i);
            }
        }
        // If no recommender is found, returns false
        return (false, 0);
    }

    //Function to return information about a particular recommendee
    function getRecommendeePosition(address _userAddress, address _sender) internal view returns (uint256 pos) {
        // Will loop through recommendees searching for a particular user
        for (uint256 i = 0; i < recommendees[_userAddress].length; i++) {
            if (recommendees[_userAddress][i].userAddress == _sender) {
                return i;
            }
        }
    }

    //Function called by candidates to penalise their recommenders
    function penalise(address _userAddress) public isRegistered(msg.sender) {
        require(users[msg.sender].status == Status.Candidate, "User must be candidate");
        // Check that userAddress is recommender of sender
        // position of recommender in sender's recommenders lists
        (bool isRecommender, uint256 position1) = getRecommenderPosition(_userAddress, msg.sender);
        require(isRecommender, "Given user is not a recommender");
        uint256 position2 = getRecommendeePosition(_userAddress, msg.sender);
        // set t to be weight
        uint256 t = recommenders[msg.sender][position1].weight;
        // reduce vcold of user
        users[_userAddress].vcold -= t;
        // remove user from sender's recommender(users who vote for you) and recommendee(users who you vote for) list
        recommenders[msg.sender][position1] = recommenders[msg.sender][recommenders[msg.sender].length - 1];
        recommenders[msg.sender].pop();
        recommendees[_userAddress][position2] = recommendees[_userAddress][recommendees[_userAddress].length - 1];
        recommendees[_userAddress].pop();
    }

    //Function called by verified identities/WorldID holders to claim rewards after voting
    function claimReward(uint256[] memory epochs) public isRegistered(msg.sender) {
        uint256 c_epoch = calculateCurrentEpoch();
        for (uint256 i = 0; i < epochs.length; i++) {
            if (epochs[i] < c_epoch && rewards_per_epoch[epochs[i]] != 0 && user_epoch_weights[msg.sender][epochs[i]] != 0) {
                // increase totalReward of the sender in users map
                users[msg.sender].totalReward +=
                    (c * user_epoch_weights[msg.sender][epochs[i]]) / rewards_per_epoch[epochs[i]];
                delete user_epoch_weights[msg.sender][epochs[i]];
            }
        }
    }

    function getListOfRecommenders(address _userAddress) public view returns (VotingPair[] memory) {
        return recommenders[_userAddress];
    }

    function getListOfRecommendees(address _userAddress) public view returns (VotingPair[] memory) {
        return recommendees[_userAddress];
    }

    function getUserEpochWeights(address user_addr, uint256 epoch) public view returns (uint256) {
        return user_epoch_weights[user_addr][epoch];
    }
}
