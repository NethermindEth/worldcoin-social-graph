// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import { Contract } from "./Contract.sol";

contract Worldcoin {
    struct VotingPair {
        uint userID;
        uint weight;
    }

    struct User{
        uint uid;
        string name;
        //two categories of Users - those who are World ID Holders 
        //and those who are candidates
        bool isWorldIDHolder;
        bool isRegistered;
        // is 0 if isWorldIDHolder = false
        uint WorldID;

        //VAL of node and is a dynamic variable
        uint vhot;
        uint vcold;
        //depends on `VAL` of node and is dynamic 
        //0 - World ID identities, 1 - Derived identities, 2 - Ascendants, 3 - Rejected
        uint status;

        uint totalReward;

        // last epoch for which the user claimed their voting rewards
        uint lepoch;
    }

    struct Rewards {
        // total number of voting power allocated to the candidates
        uint sum;
        // total number of voting power claimed by the voters
        uint claimed;
    }

    mapping (uint => Rewards) rewards_per_epoch;

    // counting weights per epoch
    // map takes epoch to corresponding weight assigned in that epoch
    mapping (address => mapping (uint => uint) epochWeights) user_epoch_weights;
    
    uint internal id = 1;
    //x is the minimum number of Verified users needed to collude in order to create fake Verified identities
    uint internal x;
    // alpha parameter that determines the percentage of the voting power that will be returned to recommenders when a candidate becomes verified
    uint internal a;
    // parameter that determines the rewards per epoch to be shared
    uint internal c;
    //stores candidates and world Id holders
    mapping(address => User) internal users;
    mapping(uint => address) internal userAddress;

    mapping(address => VotingPair[]) internal recommendees; // users who you vote/vouch for
    mapping(address => VotingPair[]) internal recommenders; // users who vote/vouch for you

    //stores the registered world ID holders
    mapping(uint => bool) internal worldIDs;

    // Modifier to check if a user is registered
    modifier isRegistered(address _user) {
        require(users[_user].isRegistered, "User is not registered");
        _;
    }

    // Modifier to check if a user is a WorldID Holder
    modifier isWorldIDHolder(address _user) {
        require(users[_user].isWorldIDHolder == true, "User does not hold a World ID");
        _;
    }

    modifier canVote(address _user) {
        require(users[_user].isRegistered, "User is not registered");
        require(users[_user].status == 0 || users[_user].status == 1, "User cannot vote");
        _;
    }
}