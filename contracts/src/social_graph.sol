// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import { Contract } from "./Contract.sol";

contract Worldcoin {
    struct User{
        uint32 uid;
        bytes32 name;
        //two categories of Users - those who are World ID Holders 
        //and those who are candidates
        bool isWorldIDHolder;
        bool isRegistered;
        // is 0 if isWorldIDHolder = false
        uint WorldID;

        //VAL of node and is a dynamic variable
        uint val;
        //depends on `VAL` of node and is dynamic 
        //0 - World ID identities, 1 - Derived identities, 2 - Ascendants, 3 - Rejected
        uint status;
        address[] recommendees; // users who you vote/vouch for
        address[] recommenders; // users who vote/vouch for you
    }
    
    uint32 public id = 0;
    //stores candidates and world Id holders
    mapping(address => User) public users;

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

}