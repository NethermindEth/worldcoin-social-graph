// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Voting} from "../src/voting.sol";
import {Script} from "../lib/forge-std/src/Script.sol";


contract DeployVoting is Script {
    function run() external returns (Voting) {
        vm.startBroadcast();
        Voting voting = new Voting();
        vm.stopBroadcast();
        return voting;
    }
}
