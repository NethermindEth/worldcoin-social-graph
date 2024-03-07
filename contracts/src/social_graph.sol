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
        bytes32 name;
        //two categories of Users - those who are World ID Holders 
        //and those who are candidates
        bool isWorldIDHolder;
        bool isRegistered;
        // is 0 if isWorldIDHolder = false
        uint WorldID;

        //VAL of node and is a dynamic variable
        uint val;
        uint vhot;
        uint vcold;
        //depends on `VAL` of node and is dynamic 
        //0 - World ID identities, 1 - Derived identities, 2 - Ascendants, 3 - Rejected
        uint status;
        VotingPair[] recommendees; // users who you vote/vouch for
        VotingPair[] recommenders; // users who vote/vouch for you

        uint totalReward;
    }
    
    uint internal id = 0;
    //x is the minimum number of Verified users needed to collude in order to create fake Verified identities
    uint internal x;
    //stores candidates and world Id holders
    mapping(address => User) public users;
    mapping(uint => address) public userAddress;
    mapping(uint => uint) public rewards;
    
    //stores the registered world ID holders ---check
    mapping(uint => bool) public worldIDs;

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