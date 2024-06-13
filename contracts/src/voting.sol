// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import { Worldcoin } from "./social_graph.sol";
import { verifyWorldID } from "./verifyWorldID.sol";
import { ABDKMath64x64 } from "@abdk-library/ABDKMath64x64.sol";

contract Voting is Worldcoin {
    verifyWorldID worldIDContract;

    /// @notice Event for user registration as World ID holder or Candidate
    event UserRegistered(address indexed user, string name, Status status);
    /// @notice Candidate verified event
    event CandidateVerified(address indexed user, string name, Status status);

    constructor(verifyWorldID _worldIDContract) {
        worldIDContract = _worldIDContract;
    }

    function inversePower(uint256 input) public pure returns (uint256) {
        // Represent the percentage as a fixed-point number.
        int128 percentage = ABDKMath64x64.divu(input, 100);

        // Calculate e^(percentage)
        int128 result = ABDKMath64x64.exp(percentage);

        // Multiply by 10^5 to keep 5 decimal places
        result = ABDKMath64x64.mul(result, ABDKMath64x64.fromUInt(1e5));

        // Invert the exponential as required
        result = ABDKMath64x64.div(ABDKMath64x64.fromUInt(1e5), result);

        // Multiply by 10^5 to keep 5 decimal places
        result = ABDKMath64x64.mul(result, ABDKMath64x64.fromUInt(1e5));

        // Convert the fixed-point result to a uint and return it.
        return ABDKMath64x64.toUInt(result);
    }

    // @todo make it private if it's not going to be inherited
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    // @todo should this be public?
    function currentEpoch() internal view returns (uint256) {
        return (block.number / 50_064) + 1;
    }

    // Function to register an account as a World ID holder
    function registerAsWorldIDHolder(
        string calldata _name,
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    )
        public
    {
        // require(!users[msg.sender].isRegistered, "User is already registered");
        require(users[msg.sender].status == Status.UNREGISTERED, "User is already registered");
        // Perform checks to verify World ID
        worldIDContract.verifyAndExecute(signal, root, nullifierHash, proof);
        // compute current epoch
        uint256 c_epoch = currentEpoch();
        // add new user to user map
        users[msg.sender] = User(_name, true, 100, 0, Status.WORLD_ID_HOLDER, 0, c_epoch - 1);
        user_epoch_weights[msg.sender][c_epoch] = 0;
    }

    // @todo use natspec comments
    // Function to register an account as a Candidate
    function registerAsCandidate(string calldata _name) external {
        require(users[msg.sender].status == Status.UNREGISTERED, "User is already registered");
        // compute current epoch
        uint256 c_epoch = currentEpoch();
        // add user to user map
        users[msg.sender] = User(_name, false, 0, 0, Status.CANDIDATE, 0, c_epoch - 1);
    }

    /**
     * @notice Function to recommend candidates
     * @param _votes Array of VotingPair structs containing the candidate and the weight of the vote
     */
    function recommendCandidates(VotingPair[] memory _votes) external canVote(msg.sender) {
        uint256 sumOfWeights = 0;
        uint256 remainingVotingPower = users[msg.sender].vhot;

        // Iterate through the array of votes
        for (uint256 i = 0; i < _votes.length; i++) {
            address candidate = _votes[i].user;
            uint256 weight = min(1000 - assignedWeight[candidate], _votes[i].weight);
            // Check if the candidate is valid
            require(users[candidate].status == Status.CANDIDATE, "WorldCoinGraph: INVALID_CANDIDATE");

            // Check if the voter has enough voting power
            require(remainingVotingPower >= weight, "WorldCoinGraph: VOTING_POWER_EXCEEDED");

            // Update the assigned weight for the candidate
            assignedWeight[candidate] += weight;

            // Update the voting power of the voter
            remainingVotingPower -= weight;
            sumOfWeights += weight;
            _votes[i].weight = weight;

            // Add the vote to the recommendees and recommenders lists
            recommendees[msg.sender].push(_votes[i]);
            recommenders[candidate].push(VotingPair(msg.sender, weight));
        }

        // Update the voter's hot and cold voting power
        users[msg.sender].vhot -= sumOfWeights;
        users[msg.sender].vcold += sumOfWeights;
    }

    //Function called by candidate to update his/her status
    function updateStatusVerified() public {
        // msg.sender should be a candidate
        require(users[msg.sender].status == Status.CANDIDATE, "WorldCoinGraph: INVALID_USER");
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < recommenders[msg.sender].length; i++) {
            //stores the total weight received as votes
            totalWeight += recommenders[msg.sender][i].weight;
        }
        require(totalWeight > x, "User should have higher power than threshold");
        //val refers to the voting power a user has
        //val currently has precision of 5 decimals
        uint256 val = 1e5 - inversePower(totalWeight / 2);

        users[msg.sender].status = Status.VERIFIED_IDENTITIY;
        users[msg.sender].vhot = val / 1e3;

        uint256 c_epoch = currentEpoch();

        for (uint256 i = 0; i < recommenders[msg.sender].length; i++) {
            uint256 _weight = recommenders[msg.sender][i].weight;
            address addressOfRecommender = recommenders[msg.sender][i].user;

            users[addressOfRecommender].vhot += (a * _weight) / 100;
            users[addressOfRecommender].vcold -= _weight;

            user_epoch_weights[addressOfRecommender][c_epoch] += _weight;
            rewards_per_epoch[c_epoch] += _weight;
        }
    }

    //Function to return information about a particular recommender
    function getRecommenderPosition(address _user, address _sender) internal view returns (bool isRec, uint256 pos) {
        // Will loop through recommenders searching for a particular user
        for (uint256 i = 0; i < recommenders[_sender].length; i++) {
            if (recommenders[_sender][i].user == _user) {
                return (true, i);
            }
        }
        // If no recommender is found, returns false
        return (false, 0);
    }

    /**
     * @notice Function to return information about a particular recommendee
     * @param _user Address of the user to search for
     * @param _sender Address of the sender
     * @return pos Position of the recommendee in the sender's recommendees list
     */
    function getRecommendeePosition(address _user, address _sender) private view returns (uint256 pos) {
        // Will loop through recommendees searching for a particular user
        for (uint256 i = 0; i < recommendees[_user].length; i++) {
            if (recommendees[_user][i].user == _sender) {
                return i;
            }
        }
    }

    /**
     * @notice Function called by candidates to penalise their recommenders
     * @param _user Address of the user to penalise
     */
    function penalise(address _user) public {
        require(users[msg.sender].status == Status.CANDIDATE, "WorldCoinGraph: USER_NOT_A_CANDIDATE");
        // Check that userAddress is recommender of sender
        // position of recommender in sender's recommenders lists
        (bool isRecommender, uint256 position1) = getRecommenderPosition(_user, msg.sender);
        require(isRecommender, "WorldCoinGraph: USER_NOT_A_RECOMMENDER");
        uint256 position2 = getRecommendeePosition(_user, msg.sender);
        // set t to be weight
        uint256 t = recommenders[msg.sender][position1].weight;
        // reduce vcold of user
        users[_user].vcold -= t;
        // remove user from sender's recommender(users who vote for you) and recommendee(users who you vote for) list
        recommenders[msg.sender][position1] = recommenders[msg.sender][recommenders[msg.sender].length - 1];
        recommenders[msg.sender].pop();
        recommendees[_user][position2] = recommenders[_user][recommenders[_user].length - 1];
        recommendees[_user].pop();
    }

    /**
     * @notice Function called by verified identities/WorldID holders to claim rewards after voting
     * @param epochs Array of epochs for which the user wants to claim rewards
     */
    function claimReward(uint256[] memory epochs) public {
        require(users[msg.sender].status != Status.UNREGISTERED, "WorldCoinGraph: UNREGISTERED_USER");
        uint256 c_epoch = currentEpoch();
        uint256 totalReward = users[msg.sender].totalReward;
        for (uint256 i = 0; i != epochs.length; i++) {
            if (epochs[i] < c_epoch) {
                // increase totalReward of the sender in users map
                totalReward += c * (user_epoch_weights[msg.sender][epochs[i]] / rewards_per_epoch[epochs[i]]);
                delete user_epoch_weights[msg.sender][epochs[i]];
            }
        }
        users[msg.sender].totalReward = totalReward;
    }

    function getListOfRecommenders(address _user) public view returns (VotingPair[] memory) {
        return recommenders[_user];
    }

    function getListOfRecommendees(address _user) public view returns (VotingPair[] memory) {
        return recommendees[_user];
    }
}
