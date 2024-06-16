// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import { IWorldcoinSocialGraphStorage } from "./IWorldcoinSocialGraphStorage.sol";

interface IWorldcoinSocialGraphVoting is IWorldcoinSocialGraphStorage {
    /// @notice Event for user registration as World ID holder or Candidate
    event UserRegistered(address indexed user, Status status);

    /// @notice Candidate verified event
    event CandidateVerified(address indexed user, Status status);

    /// @notice Event for reward claims
    event RewardClaimed(address indexed user, uint256 reward);

    /// @notice Event for penalising a user
    event Penalised(address indexed recommender, address indexed recommendee, uint256 weight);

    /**
     * @notice Function to calculate the inverse power of a number
     * @param input The input number
     * @return inverse power of the input number
     */
    function inversePower(uint256 input) external pure returns (uint256);

    /**
     * @notice Function to calculate the current epoch
     * @return current epoch
     */
    function currentEpoch() external view returns (uint256);

    /**
     * @notice Function to register an account as a World ID holder
     * @param _name Name of the user
     * @param _signal Signal for the World ID
     * @param _root Root of the World ID
     * @param _nullifierHash Nullifier hash of the World ID
     * @param _proof Array of proof elements
     */
    function registerAsWorldIDHolder(
        string calldata _name,
        address _signal,
        uint256 _root,
        uint256 _nullifierHash,
        uint256[8] calldata _proof
    ) external;

    /**
     * @notice Function to register an account as a Candidate
     * @param _name Name of the candidate
     */
    function registerAsCandidate(string calldata _name) external;

    /**
     * @notice Function to recommend candidates
     * @param _votes Array of VotingPair structs containing the candidate and the weight of the vote
     */
    function recommendCandidates(VotingPair[] memory _votes) external;

    /**
     * @notice Function called by candidate to update his/her status
     */
    function updateStatusVerified() external;

    /**
     * @notice Function called by candidates to penalise their recommenders
     * @param _user Address of the user to penalise
     */
    function penalise(address _user) external;

    /**
     * @notice Function called by verified identities/WorldID holders to claim rewards after voting
     * @param epochs Array of epochs for which the user wants to claim rewards
     */
    function claimReward(uint256[] memory epochs) external;

    /**
     * @notice Function to retrieve the list of recommenders for a user
     * @param _userAddress Address of the user
     * @return Array of VotingPair structs representing the recommenders
     */
    function getListOfRecommenders(address _userAddress) external view returns (VotingPair[] memory);

    /**
     * @notice Function to retrieve the list of recommendees for a user
     * @param _userAddress Address of the user
     * @return Array of VotingPair structs representing the recommendees
     */
    function getListOfRecommendees(address _userAddress) external view returns (VotingPair[] memory);
}