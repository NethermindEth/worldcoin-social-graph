// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import { Test } from "../lib/forge-std/src/Test.sol";

import { WorldcoinSocialGraphVoting } from "../src/WorldcoinSocialGraphVoting.sol";
import { WorldcoinVerifierMock } from "./Mocks/WorldcoinVerifierMock.sol";
import { WorldcoinSocialGraphStorage } from "../src/WorldcoinSocialGraphStorage.sol";
import { IWorldcoinSocialGraphStorage } from "../src/interfaces/IWorldcoinSocialGraphStorage.sol";
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

    /// @dev helper function to assert correct all the registration parameters
    /// @param _name - name of world ID user to be registered
    /// @param wID_addr - address world ID signed up with
    function register_worldID_test(string memory _name, address wID_addr) public {
        voting.registerAsWorldIDHolder(_name, address(0), 0, 0, [uint256(0), 0, 0, 0, 0, 0, 0, 0]);
        (, uint256 vhot, uint256 vcold, IWorldcoinSocialGraphStorage.Status status, uint256 totalReward) =
            voting.users(wID_addr);

        assertEq(vhot, 100, "Incorrect vhot");
        assertEq(vcold, 0, "Incorrect vcold");
        assertTrue(status == IWorldcoinSocialGraphStorage.Status.WORLD_ID_HOLDER, "Incorrect worldID status");
        assertEq(totalReward, 0, "Incorrect total reward");
    }

    /// @dev helper function to assert correct all the registration parameters
    /// @param _name - name of candidate user to be registered
    /// @param can_addr - address candidate signed up with
    function register_candidate_test(string memory _name, address can_addr) public {
        voting.registerAsCandidate(_name);

        (, uint256 vhot, uint256 vcold, IWorldcoinSocialGraphStorage.Status status, uint256 totalReward) =
            voting.users(can_addr);

        assertEq(vhot, 0, "Incorrect vhot");
        assertEq(vcold, 0, "Incorrect vcold");
        assertTrue(status == IWorldcoinSocialGraphStorage.Status.CANDIDATE, "Incorrect worldID status");
        assertEq(totalReward, 0, "Incorrect total reward");
    }
}
