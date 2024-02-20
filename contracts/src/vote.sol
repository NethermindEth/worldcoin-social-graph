// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./social_graph.sol";
import {ExponentialCalculator} from "./helpers/exponential.sol";

contract Voting is Worldcoin {
    ExponentialCalculator e;
    constructor(address _address) {
        e = ExponentialCalculator(_address);
    }

    function assignStatus(uint val) internal pure returns(uint) {
        //0 - World ID identities, 1 - Derived identities, 2 - Ascendants, 3 - Rejected
        if(val>=1)
            return 1;
        else if(val<0)
            return 3;
        else return 2;
    }

    function recommendCandidate(address _candidate, uint _levelOfVote) external isRegistered(msg.sender) {
        require(users[_candidate].isRegistered, "Candidate not registered");
        require(_levelOfVote == 1 || _levelOfVote == 2 || _levelOfVote == 3, "Level of vote can only be 1, 2 or 3");
        //adding relevant information about voting to the struct
        users[msg.sender].recommendees.push(_candidate);
        users[_candidate].recommenders.push(msg.sender);

        //assign value to the candidate node
        //maximum value of any user at any point can only be 100 - //TODO
        uint eVal = users[msg.sender].val * _levelOfVote;
        uint currentVal = users[_candidate].val;
        //TODO
        users[_candidate].val = 100 - e.calculateReverseExp((currentVal + eVal/3));

        //assign status according to VAL of node
        users[_candidate].status = assignStatus(users[_candidate].val);
    }
}