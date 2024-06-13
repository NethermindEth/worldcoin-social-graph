// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import { Worldcoin } from "./social_graph.sol";
import { verifyWorldID } from "./verifyWorldID.sol";
import { ABDKMath64x64 } from "@abdk-library/ABDKMath64x64.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract Voting is Worldcoin {
    verifyWorldID public immutable worldIDContract;

    /// @notice Event for user registration as World ID holder or Candidate
    event UserRegistered(address indexed user, Status status);
    /// @notice Candidate verified event
    event CandidateVerified(address indexed user, Status status);
    /// @notice Event for reward claims
    event RewardClaimed(address indexed user, uint256 reward);
    /// @notice Event for penalising a user
    event Penalised(address indexed recommender, address indexed recommendee, uint256 weight);

    constructor(verifyWorldID _worldIDContract) {
        worldIDContract = _worldIDContract;
    }

    //////////////////////
    // Public functions //
    //////////////////////

    /**
     * @notice Function to calculate the inverse power of a number
     * @param input The input number
     * @return inverse power of the input number
     */
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

    /**
     * @notice Function to calculate the current epoch
     * @return current epoch
     */
    function currentEpoch() public view returns (uint256) {
        return (block.number / 50_064) + 1;
    }

    /**
     * @notice Function to register an account as a World ID holder
     * @param _name Name of the user
     * @param _signal Signal for the World ID
     * @param _root Root of the World ID
     * @param _nullifierHash Nullifier hash of the World ID
     * @param _proof Array of proof elements
     */
    // Function to register an account as a World ID holder
    function registerAsWorldIDHolder(
        string calldata _name,
        address _signal,
        uint256 _root,
        uint256 _nullifierHash,
        uint256[8] calldata _proof
    )
        public
        onlyUnregistered(msg.sender)
    {
        // Perform checks to verify World ID
        worldIDContract.verifyAndExecute(_signal, _root, _nullifierHash, _proof);
        // compute current epoch
        uint256 c_epoch = currentEpoch();
        // add new user to user map
        users[msg.sender] = User(_name, true, 100, 0, Status.WORLD_ID_HOLDER, 0, c_epoch - 1);
        emit UserRegistered(msg.sender, Status.WORLD_ID_HOLDER);
    }

    /**
     * @notice Function to register an account as a Candidate
     * @param _name Name of the candidate
     */
    function registerAsCandidate(string calldata _name) public onlyUnregistered(msg.sender) {
        // compute current epoch
        uint256 c_epoch = currentEpoch();
        // add user to user map
        users[msg.sender] = User(_name, false, 0, 0, Status.CANDIDATE, 0, c_epoch - 1);
        emit UserRegistered(msg.sender, Status.CANDIDATE);
    }

    /**
     * @notice Function to recommend candidates
     * @param _votes Array of VotingPair structs containing the candidate and the weight of the vote
     */
    function recommendCandidates(VotingPair[] memory _votes) public onlyValidVoter(msg.sender) {
        uint256 sumOfWeights = 0;
        uint256 remainingVotingPower = users[msg.sender].vhot;

        // Iterate through the array of votes
        for (uint256 i = 0; i < _votes.length; i++) {
            address candidate = _votes[i].user;
            uint256 weight = Math.min(1000 - assignedWeight[candidate], _votes[i].weight);
            // Check if the candidate is valid
            require(users[candidate].status == Status.CANDIDATE, "WorldcoinGraph: INVALID_CANDIDATE");

            // Check if the voter has enough voting power
            require(remainingVotingPower >= weight, "WorldcoinGraph: VOTING_POWER_EXCEEDED");

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

    /**
     * @notice Function called by candidate to update his/her status
     */
    function updateStatusVerified() public {
        // msg.sender should be a candidate
        require(users[msg.sender].status == Status.CANDIDATE, "WorldcoinGraph: INVALID_USER");
        uint256 totalWeight = assignedWeight[msg.sender];
        require(totalWeight > x, "WorldcoinGraph: INSUFFICIENT_VOTING_POWER");
        // val refers to the voting power a user with a precision of 5 decimals
        uint256 val = 1e5 - inversePower(totalWeight / 2);

        users[msg.sender].status = Status.VERIFIED_IDENTITIY;
        users[msg.sender].vhot = val / 1e3;

        uint256 c_epoch = currentEpoch();
        uint256 rewardsInCurrentEpoch = rewardsPerEpoch[c_epoch];
        for (uint256 i = 0; i < recommenders[msg.sender].length; i++) {
            uint256 _weight = recommenders[msg.sender][i].weight;
            address addressOfRecommender = recommenders[msg.sender][i].user;

            users[addressOfRecommender].vhot += Math.mulDiv(a, _weight, 100);
            users[addressOfRecommender].vcold -= _weight;

            userEpochWeights[addressOfRecommender][c_epoch] += _weight;
            rewardsInCurrentEpoch += _weight;
        }
        rewardsPerEpoch[c_epoch] = rewardsInCurrentEpoch;

        emit CandidateVerified(msg.sender, Status.VERIFIED_IDENTITIY);
    }

    /**
     * @notice Function called by candidates to penalise their recommenders
     * @param _user Address of the user to penalise
     */
    function penalise(address _user) public {
        require(users[msg.sender].status == Status.CANDIDATE, "WorldcoinGraph: INVALID_USER");
        // Check that userAddress is recommender of sender
        // position of recommender in sender's recommenders lists
        (bool isRecommender, uint256 position1) = getRecommenderPosition(_user, msg.sender);
        require(isRecommender, "WorldcoinGraph: RECOMMENDER_NOT_FOUND");
        uint256 position2 = getRecommendeePosition(_user, msg.sender);
        uint256 t = recommenders[msg.sender][position1].weight;
        // reduce vcold of user by weight of recommender
        users[_user].vcold -= t;
        // remove user from sender's recommender(users who vote for you) and recommendee(users who you vote for) list
        recommenders[msg.sender][position1] = recommenders[msg.sender][recommenders[msg.sender].length - 1];
        recommenders[msg.sender].pop();
        recommendees[_user][position2] = recommenders[_user][recommenders[_user].length - 1];
        recommendees[_user].pop();

        emit Penalised(msg.sender, _user, t);
    }

    /**
     * @notice Function called by verified identities/WorldID holders to claim rewards after voting
     * @param epochs Array of epochs for which the user wants to claim rewards
     */
    function claimReward(uint256[] memory epochs) public onlyValidVoter(msg.sender) {
        uint256 c_epoch = currentEpoch();
        uint256 totalReward = users[msg.sender].totalReward;
        for (uint256 i = 0; i != epochs.length; i++) {
            uint256 epoch = epochs[i];
            if (epoch < c_epoch) {
                uint256 epochWeight = userEpochWeights[msg.sender][epoch];
                // increase totalReward of the sender in users map
                if (epochWeight > 0) {
                    totalReward += Math.mulDiv(c, epochWeight, rewardsPerEpoch[epoch]);
                    delete userEpochWeights[msg.sender][epoch];
                }
            }
        }
        users[msg.sender].totalReward = totalReward;
        emit RewardClaimed(msg.sender, totalReward);
    }

    ///////////////////////
    // Private functions //
    ///////////////////////

    /// @notice Function to return information about a particular recommender
    function getRecommenderPosition(address _user, address _sender) private view returns (bool isRec, uint256 pos) {
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
     * @notice Function to return array position of the recommendee
     * @param _user Address of the user to search for
     * @param _sender Address of the sender
     * @return pos Position of the recommendee in the sender's recommendees list
     */
    function getRecommendeePosition(address _user, address _sender) private view returns (uint256 pos) {
        // Will loop through recommendees searching for a particular user
        for (uint256 i = 0; i != recommendees[_user].length; i++) {
            if (recommendees[_user][i].user == _sender) {
                return i;
            }
        }
    }
}
