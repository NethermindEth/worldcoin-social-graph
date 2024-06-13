// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Worldcoin {
    struct VotingPair {
        address userAddress;
        uint256 weight;
    }

    enum Status {
        WorldIDHolder,
        VerifiedIdentity,
        Candidate,
        Rejected
    }

    struct User {
        string name;
        //two categories of Users - those who are World ID Holders
        //and those who are candidates
        bool isWorldIDHolder;
        bool isRegistered;
        //VAL of node and is a dynamic variable
        uint256 vhot;
        uint256 vcold;
        //depends on `VAL` of node and is dynamic
        //0 - World ID identities, 1 - Derived identities, 2 - Ascendants, 3 - Rejected
        Status status;
        uint256 totalReward;
        // last epoch for which the user claimed their voting rewards
        uint256 lepoch;
    }

    // total amount of voting power allocated to the candidates
    //maps epoch to sum
    mapping(uint256 => uint256) public rewards_per_epoch;

    // counting weights per epoch
    // for one user, the map takes epoch to corresponding weight that user has assigned to users that become verified in that epoch
    mapping(address => mapping(uint256 => uint256) epochWeights) user_epoch_weights;

    //x is the minimum power of Verified users needed in order to create fake Verified identities
    uint256 internal x = 600;
    // alpha parameter that determines the percentage of the voting power that will be returned to recommenders when a candidate becomes verified
    uint256 internal a = 60;
    // parameter that determines the rewards per epoch to be shared
    uint256 internal c = 140000;
    //stores candidates and world Id holders
    mapping(address => User) public users;
    //sum of weights allocated to a candidate user
    mapping(address => uint256) public assignedWeight;

    mapping(address => VotingPair[]) internal recommendees; // users who you vote/vouch for
    mapping(address => VotingPair[]) internal recommenders; // users who vote/vouch for you

    // Modifier to check if a user is registered
    modifier isRegistered(address _user) {
        require(users[_user].isRegistered, "User is not registered");
        _;
    }

    // Modifier to check if a user is a WorldID Holder
    modifier isWorldIDHolder(address _user) {
        require(users[_user].isWorldIDHolder, "User does not hold a World ID");
        _;
    }

    modifier canVote(address _user) {
        require(users[_user].isRegistered, "User is not registered");
        require(
            users[_user].status == Status.WorldIDHolder || users[_user].status == Status.VerifiedIdentity,
            "User cannot vote"
        );
        _;
    }
}
