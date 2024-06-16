// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import {IWorldcoinSocialGraphStorage} from "./interfaces/IWorldcoinSocialGraphStorage.sol";

contract WorldcoinSocialGraphStorage is IWorldcoinSocialGraphStorage{
    /// @notice total amount of voting power allocated to the candidates
    /// @dev maps epoch to sum
    mapping(uint256 epoch => uint256 distributedVotingPower) public rewardsPerEpoch;

    /// @notice counting weights per epoch
    /// @dev for one user, the map takes epoch to corresponding weight that user has assigned to users that become
    /// verified in that epoch
    mapping(address => mapping(uint256 => uint256) epochWeights) public userEpochWeights;

    //x is the minimum power of Verified users needed in order to create fake Verified identities
    uint16 internal constant x = 600;
    // alpha parameter that determines the percentage of the voting power that will be returned to recommenders when a
    // candidate becomes verified
    uint8 internal constant a = 60;
    // parameter that determines the rewards per epoch to be shared
    uint32 internal constant c = 140_000;
    //stores candidates and world Id holders
    mapping(address => User) public users;
    //sum of weights allocated to a candidate user
    mapping(address => uint256) public assignedWeight;

    mapping(address => VotingPair[]) internal recommendees; // users who you vote/vouch for
    mapping(address => VotingPair[]) internal recommenders; // users who vote/vouch for you

    modifier onlyUnregistered(address _user) {
        require(users[_user].status == Status.UNREGISTERED, "WorldcoinGraph: ALREADY_REGISTERED");
        _;
    }

    modifier onlyValidVoter(address _user) {
        require(
            users[_user].status == Status.WORLD_ID_HOLDER || users[_user].status == Status.VERIFIED_IDENTITY,
            "WorldcoinGraph: INVALID_VOTER"
        );
        _;
    }
}
