// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./social_graph.sol";

contract Register is Worldcoin {
    // Function to register an account as a World ID holder
    function registerAsWorldIDHolder(
        uint _worldID, 
        bytes32 _name,
        Contract _contract,
        address signal, 
        uint256 root, 
        uint256 nullifierHash, 
        uint256[8] calldata proof
        ) public {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // Perform checks to verify World ID
        _contract.verifyAndExecute(signal, root, nullifierHash, proof);
        // checks if world ID is already registered
        require(!worldIDs[_worldID], "This World ID is already registered");
        worldIDs[_worldID] = true;
        // compute current epoch
        uint c_epoch = (block.number/50064) + 1;
        // add new user to user map
        // TODO correct the passing of empty mapping epochWeights
        VotingPair[] memory vp;
        users[msg.sender] = User(id, _name, true, true, _worldID, 100, 0, 0, vp, vp, 0, c_epoch - 1);
        user_epoch_weights[msg.sender][c_epoch] = 0;
        userAddress[id++] = msg.sender;
    }
    
    // Function to register an account as a Candidate
    function registerAsCandidate(bytes32 _name) external {
        require(!users[msg.sender].isRegistered, "User is already registered");
        // compute current epoch
        uint c_epoch = (block.number/50064) + 1;
        // add user to user map
        VotingPair[] memory vp;
        users[msg.sender] = User(id, _name, false, true, 0, 0, 0, 2, vp, vp, 0, c_epoch - 1);
        userAddress[id++] = msg.sender;
    }
}