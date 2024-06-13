// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Worldcoin {
    struct VotingPair {
        address user; // @todo rename "userAddress"-> "user"
        uint256 weight;
    }

    /// @todo Change the names to actual statuses
    enum Status {
        UNREGISTERED,
        WORLD_ID_HOLDER,
        CANDIDATE,
        VERIFIED_IDENTITIY,
        REJECTED
    }

    struct User {
        string name;
        //two categories of Users - those who are World ID Holders
        //and those who are candidates
        bool isWorldIDHolder;
        //VAL of node and is a dynamic variable
        uint256 vhot;
        uint256 vcold;
        //depends on `VAL` of node and is dynamic
        /// @notice Status enum
        Status status;
        uint256 totalReward;
        // last epoch for which the user claimed their voting rewards
        uint256 lepoch;
    }

    /// @notice total amount of voting power allocated to the candidates
    /// @dev maps epoch to sum
    mapping(uint256 epoch => uint256 distributedVotingPower) rewards_per_epoch;

    // counting weights per epoch
    // for one user, the map takes epoch to corresponding weight that user has assigned to users that become verified in
    // that epoch
    mapping(address => mapping(uint256 => uint256) epochWeights) user_epoch_weights;

    //x is the minimum power of Verified users needed in order to create fake Verified identities
    uint16 internal constant x = 600;
    // alpha parameter that determines the percentage of the voting power that will be returned to recommenders when a
    // candidate becomes verified
    uint8 internal constant a = 60;
    // parameter that determines the rewards per epoch to be shared
    uint32 internal constant c = 140_000;
    //stores candidates and world Id holders
    mapping(address => User) internal users; // @todo change to public?
    //sum of weights allocated to a candidate user
    mapping(address => uint256) assignedWeight;

    mapping(address => VotingPair[]) internal recommendees; // users who you vote/vouch for
    mapping(address => VotingPair[]) internal recommenders; // users who vote/vouch for you

    modifier canVote(address _user) {
        require(
            users[_user].status == Status.WORLD_ID_HOLDER || users[_user].status == Status.VERIFIED_IDENTITIY,
            "WorldcoinGraph: INVALID_VOTER"
        );
        _;
    }
}
