// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { WorldcoinSocialGraphVoting } from "../src/WorldcoinSocialGraphVoting.sol";
import { WorldcoinVerifierMock } from "./Mocks/WorldcoinVerifierMock.sol";
import { WorldcoinSocialGraphStorage } from "../src/WorldcoinSocialGraphStorage.sol";
import { DeployVoting } from "../scripts/voting.s.sol";
import { IWorldcoinVerifier } from "../src/interfaces/IWorldcoinVerifier.sol";

contract WorldcoinSocialGraphTestUtil is Test {
    WorldcoinSocialGraphStorage storageContract;
    WorldcoinSocialGraphVoting voting;
    WorldcoinVerifierMock verifierContract;

    function setupContracts() public {
        storageContract = new WorldcoinSocialGraphStorage();
        verifierContract = new WorldcoinVerifierMock();
        voting = new WorldcoinSocialGraphVoting(IWorldcoinVerifier(address(verifierContract)));
    }
}
