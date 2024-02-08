// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

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

    // Function to register an account as a World ID holder
    function registerAsWorldIDHolder(uint _worldID, bytes32 _name) public {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // Perform checks to verify World ID - how?????
        // checks if world ID is already registered
        require(!worldIDs[_worldID], "This World ID is already registered");
        worldIDs[_worldID] = true;
        users[msg.sender] = User(id++, _name, true, true, _worldID, 1, 0, new address[](0), new address[](0));
    }
    
    // Function to register an account as a Candidate
    function registerAsCandidate(bytes32 _name) external {
        require(!users[msg.sender].isRegistered, "User is already registered");
        users[msg.sender] = User(id++, _name, false, true, 0, 1, 2, new address[](0), new address[](0));
    }

    function assignStatus(uint val) internal pure returns(uint) {
        if(val>=1)
        return 1;
        else if(val<0)
        return 3;
        else return 2;
    }

    function recommendCandidate(address _candidate) external isRegistered(msg.sender) {
    
    require(users[_candidate].isRegistered, "Candidate not registered");
    //adding relevant information about voting to the struct
    users[msg.sender].recommendees.push(_candidate);
    users[_candidate].recommenders.push(msg.sender);

    //update value - figure out!!!

    //assign status according to VAL of node
    users[_candidate].status = assignStatus(users[_candidate].val);
    }
}