// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Voting} from "../voting.sol";
import {verifyWorldID} from "../verifyWorldID.sol";
import {Worldcoin} from "../social_graph.sol";
import {DeployVoting} from "../scripts/voting.s.sol";

import {Test} from "../../lib/forge-std/src/Test.sol";

/// @title Testing for social graph
contract SocialGraphTest is Test {
    Voting voting;
    Worldcoin.VotingPair[] vp;
    uint256[] epochs;

    /// @notice will create a new voting contract for each test
    function setUp() external {
        DeployVoting dv = new DeployVoting();
        voting = dv.run();
    }

    /// @notice will test the worldID registration function
    function test_worldID_register() public {
        assertTrue(register_worldID_test("Jim", address(this)), "Could not register worldID");
    }

    /// @notice Tests the registration of a candidate.
    /// @dev This function calls `register_candidate_test` with a sample name and address, and asserts the registration was successful.
    function test_candidate_register() public {
        assertTrue(register_candidate_test("Pam", address(this)), "Could not register candidate");
    }

    /// @notice Tests the registration of a candidate and expects a revert if the same sender tries to register again.
    /// @dev This function first registers a candidate and then attempts to register the same candidate again to trigger a revert.
    function test_revert_register_can_for_same_sender() public {
        assertTrue(register_candidate_test("Pam", address(this)), "Could not register candidate");
        vm.expectRevert("User is already registered");
        assertTrue(register_candidate_test("Pam", address(this)), "Could not register candidate");
    }

    /// @notice Tests the registration of a World ID and expects a revert if the same sender tries to register again.
    /// @dev This function first registers a World ID and then attempts to register the same World ID again to trigger a revert.
    function test_revert_register_wID_for_same_sender() public {
        assertTrue(register_worldID_test("Jim", address(this)), "Could not register worldID");
        vm.expectRevert("User is already registered");
        assertTrue(register_worldID_test("Jim", address(this)), "Could not register worldID");
    }

    /// @notice Tests the voting of a candidate by a world ID where they have both correctly registered.
    /// @dev First will register the world ID and the candidate then will recommend the candidate with vote weight of 100 (i.e. all its weight).
    function test_vote_for_1() public {
        assertTrue(register_worldID_test("Michael", address(this)), "Could not sign up user");

        vm.prank(address(1234));
        assertTrue(register_candidate_test("Dwight", address(1234)));
        vm.stopPrank();
                
        vp.push(Worldcoin.VotingPair(address(1234), 100));
        
        voting.recommendCandidate(vp);

        // check that assigned weight of canidate = weight
        assertEq(voting.assignedWeight(address(1234)), 100, "incorrect weight assigned");
        // check that the voting pair in recommendee[msg.sender] is equal to that in vp
        assertEq(voting.getListOfRecommendees(address(this)).length, 1, "incorrect recommendee length");
        assertEq(voting.getListOfRecommendees(address(this))[0].weight, 100, "incorrect weight in recommendees");
        // check that the voting pair pushed in recommender[candidate] is that of msg.sender and 100
        assertEq(voting.getListOfRecommenders(address(1234)).length, 1, "incorrect recommendee length");
        assertEq(voting.getListOfRecommenders(address(1234))[0].weight, 100, "incorrect weight in recommendees");
        assertEq(voting.getListOfRecommenders(address(1234))[0].userAddress, address(this), "incorrect weight in recommendees");
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
    }
    /// @notice Tests the voting process with an incorrect candidate address and expects a revert.
    /// @dev This function registers a World ID user and then attempts to vote with a fake candidate address.
    function test_revert_vote_incorrect_candidate(address fake_can_addr) public {
        assertTrue(register_worldID_test("Michael", address(this)), "Could not register worldID user");

        vp.push(Worldcoin.VotingPair(fake_can_addr, 100));
        vm.expectRevert();
        voting.recommendCandidate(vp);

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
    }

    /// @notice Tests the voting process when the World ID is not registered and expects a revert.
    /// @dev This function attempts to vote without registering the World ID, expecting the `recommendCandidate` function to revert with the message "User is not registered".
    function test_revert_vote_wID_not_registered(address fake_can_addr) public {
        // Note: Here since the address calling the function is not signed up we can just call recommend
        
        vp.push(Worldcoin.VotingPair(fake_can_addr, 100));
        vm.expectRevert("User is not registered");
        voting.recommendCandidate(vp);

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
    }

    /// @notice Tests the voting process by a registered candidate and expects a revert.
    /// @dev This function registers a candidate and then attempts to vote, expecting the `recommendCandidate` function to revert with the message "User cannot vote".
    function test_revert_candidate_vote(address fake_can_addr) public {
        assertTrue(register_candidate_test("Ross", address(this)), "Could not register candidate");
        
        vp.push(Worldcoin.VotingPair(fake_can_addr, 100));
        vm.expectRevert("User cannot vote");
        voting.recommendCandidate(vp);

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
    }


    /// @notice will test the update status function to check that a candidate can become a verified identity
    /// @dev will register 7 world IDs and vote with all their voting power to overcome the threshold allowing 
    /// the can to become verified.
    function test_update_status_verified_7_wID_with_100_voting_power_each() public {        
        assertTrue(register_candidate_test("Andy", address(this)));
                
        // sign up 1
        startHoax(address(1234));
        assertTrue(register_worldID_test("Jim", address(1234)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(1234)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 2
        startHoax(address(2345));
        assertTrue(register_worldID_test("Pam", address(2345)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(2345)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 3
        startHoax(address(3456));
        assertTrue(register_worldID_test("Michael", address(3456)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(3456)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 4
        startHoax(address(4567));
        assertTrue(register_worldID_test("Dwight", address(4567)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(4567)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 5
        startHoax(address(5678));
        assertTrue(register_worldID_test("Ryan", address(5678)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(5678)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 6
        startHoax(address(6789));
        assertTrue(register_worldID_test("Kelly", address(6789)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(6789)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 7
        startHoax(address(7890));
        assertTrue(register_worldID_test("Toby", address(7890)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(7890)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // candidate calls update status
        voting.updateStatusVerified();
        Worldcoin.User memory verified_candidate = voting.getUser(address(this));
        assertTrue(verified_candidate.status == Worldcoin.Status.VerifiedIdentity, "Did not update status");
        assertEq(verified_candidate.vhot, 96, "Did not update status");
        assertEq(verified_candidate.vcold, 0, "Did not update status");
    
        // check vhot of wID voters
        assertEq(voting.getUser(address(1234)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(2345)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(3456)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(4567)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(5678)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(6789)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(7890)).vhot, 60, "Must have vhot = alpha * 100");
    }

    /// @notice will test the update status function that it reverts if not voting power is not over threshold
    /// @dev will register 6 world IDs and vote with all their voting power but will revert as it is not enough
    /// voting power.
    function test_revert_update_status_verified_6_wID_with_100_voting_power_each() public {       
        assertTrue(register_candidate_test("Andy", address(this)));
                
        // sign up 1
        startHoax(address(1234));
        assertTrue(register_worldID_test("Jim", address(1234)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 2
        startHoax(address(2345));
        assertTrue(register_worldID_test("Pam", address(2345)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 3
        startHoax(address(3456));
        assertTrue(register_worldID_test("Michael", address(3456)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 4
        startHoax(address(4567));
        assertTrue(register_worldID_test("Dwight", address(4567)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 5
        startHoax(address(5678));
        assertTrue(register_worldID_test("Ryan", address(5678)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 6
        startHoax(address(6789));
        assertTrue(register_worldID_test("Kelly", address(6789)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // candidate calls update status
        vm.expectRevert("User should have higher power than threshold");
        voting.updateStatusVerified();
    }

    /// @notice will test the update status function to check that a candidate can become a verified identity
    /// @dev will register 13 world IDs and vote with half their voting power to overcome the threshold allowing 
    /// the can to become verified.
    function test_update_status_verified_13_wID_with_50_voting_power_each() public {
        assertTrue(register_candidate_test("Andy", address(this)));

        // sign up 1
        startHoax(address(1234));
        assertTrue(register_worldID_test("Jim", address(1234)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 2
        startHoax(address(2345));
        assertTrue(register_worldID_test("Pam", address(2345)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 3
        startHoax(address(3456));
        assertTrue(register_worldID_test("Michael", address(3456)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 4
        startHoax(address(4567));
        assertTrue(register_worldID_test("Dwight", address(4567)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 5
        startHoax(address(5678));
        assertTrue(register_worldID_test("Ryan", address(5678)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 6
        startHoax(address(6789));
        assertTrue(register_worldID_test("Kelly", address(6789)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 7
        startHoax(address(7890));
        assertTrue(register_worldID_test("Toby", address(7890)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 8
        startHoax(address(8910));
        assertTrue(register_worldID_test("Ryan", address(8910)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 9
        startHoax(address(91011));
        assertTrue(register_worldID_test("Phylis", address(91011)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 10
        startHoax(address(101112));
        assertTrue(register_worldID_test("Stanley", address(101112)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 11
        startHoax(address(111213));
        assertTrue(register_worldID_test("Creed", address(111213)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 12
        startHoax(address(121314));
        assertTrue(register_worldID_test("Angela", address(121314)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 13
        startHoax(address(131415));
        assertTrue(register_worldID_test("Oscar", address(131415)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // sign up 14
        startHoax(address(141516));
        assertTrue(register_worldID_test("Kevin", address(141516)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 50));
        
        voting.recommendCandidate(vp);
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
        vm.stopPrank();

        // candidate calls update status
        voting.updateStatusVerified();
        Worldcoin.User memory verified_candidate = voting.getUser(address(this));
        assertTrue(verified_candidate.status == Worldcoin.Status.VerifiedIdentity, "Did not update status");
        assertEq(verified_candidate.vhot, 96, "Did not update status");
        assertEq(verified_candidate.vcold, 0, "Did not update status");
    }

    /// @notice will test the claim function when the candidate has become verifed and the world ID claims its rewards
    /// @dev will register 7 world IDs and vote with all their voting power to overcome the threshold allowing 
    /// the can to become verified, will call the update status and then the claim.
    function test_claim_candidate_is_verified() public {
        assertTrue(register_candidate_test("Andy", address(this)));

        // sign up 1
        startHoax(address(1234));
        assertTrue(register_worldID_test("Jim", address(1234)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(1234)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 2
        startHoax(address(2345));
        assertTrue(register_worldID_test("Pam", address(2345)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(2345)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 3
        startHoax(address(3456));
        assertTrue(register_worldID_test("Michael", address(3456)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(3456)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 4
        startHoax(address(4567));
        assertTrue(register_worldID_test("Dwight", address(4567)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(4567)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 5
        startHoax(address(5678));
        assertTrue(register_worldID_test("Ryan", address(5678)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(5678)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 6
        startHoax(address(6789));
        assertTrue(register_worldID_test("Kelly", address(6789)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(6789)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 7
        startHoax(address(7890));
        assertTrue(register_worldID_test("Toby", address(7890)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(7890)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // candidate calls update status
        voting.updateStatusVerified();
        Worldcoin.User memory verified_candidate = voting.getUser(address(this));
        assertTrue(verified_candidate.status == Worldcoin.Status.VerifiedIdentity, "Did not update status");
        assertEq(verified_candidate.vhot, 96, "Did not update status");
        assertEq(verified_candidate.vcold, 0, "Did not update status");
    
        // check vhot of wID voters
        assertEq(voting.getUser(address(1234)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(2345)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(3456)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(4567)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(5678)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(6789)).vhot, 60, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(7890)).vhot, 60, "Must have vhot = alpha * 100");
    
        // check rewards of wID voters
        assertEq(voting.getUser(address(1234)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(2345)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(3456)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(4567)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(5678)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(6789)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(7890)).totalReward, 0, "Must have vhot = alpha * 100");

        vm.roll(200000);

        uint256 curr_epoch = (block.number / 50064) + 1;
        uint256 lepoch = voting.getUser(address(1234)).lepoch;

        for (uint256 epoch = lepoch+1; epoch < curr_epoch; epoch++) {
            epochs.push(epoch);
        }

        uint len = epochs.length;

        vm.prank(address(1234));
        voting.claimReward(epochs);
        assertEq(voting.getUser(address(1234)).totalReward, 20000, "Must have vhot = alpha * 100");

        for (uint256 i = 0; i < len; i++) {
            epochs.pop();
        }
        assertEq(epochs.length, 0, "epochs must return to original length");
    } 

    /// @notice will test claim function when the candidate has not become verifed and the world ID claims its rewards
    /// @dev will register 7 world IDs and vote with all their voting power to overcome the threshold allowing the
    /// candidate to become verified, will call the update status and then the claim but the rewards must not change.
    function test_claim_candidate_is_not_verified() public {
        assertTrue(register_candidate_test("Andy", address(this)));

        // sign up 1
        startHoax(address(1234));
        assertTrue(register_worldID_test("Jim", address(1234)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(1234)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 2
        startHoax(address(2345));
        assertTrue(register_worldID_test("Pam", address(2345)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(2345)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 3
        startHoax(address(3456));
        assertTrue(register_worldID_test("Michael", address(3456)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(3456)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 4
        startHoax(address(4567));
        assertTrue(register_worldID_test("Dwight", address(4567)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(4567)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 5
        startHoax(address(5678));
        assertTrue(register_worldID_test("Ryan", address(5678)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(5678)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 6
        startHoax(address(6789));
        assertTrue(register_worldID_test("Kelly", address(6789)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(6789)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        // sign up 7
        startHoax(address(7890));
        assertTrue(register_worldID_test("Toby", address(7890)), "Could not register worldID");
        vp.push(Worldcoin.VotingPair(address(this), 100));
        
        voting.recommendCandidate(vp);
        assertEq(voting.getUser(address(7890)).vhot, 0, "User must have voted will all voting power");
        vm.stopPrank();

        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");
    
        // check vhot of wID voters
        assertEq(voting.getUser(address(1234)).vhot, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(2345)).vhot, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(3456)).vhot, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(4567)).vhot, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(5678)).vhot, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(6789)).vhot, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(7890)).vhot, 0, "Must have vhot = alpha * 100");
    
        // check rewards of wID voters
        assertEq(voting.getUser(address(1234)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(2345)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(3456)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(4567)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(5678)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(6789)).totalReward, 0, "Must have vhot = alpha * 100");
        assertEq(voting.getUser(address(7890)).totalReward, 0, "Must have vhot = alpha * 100");

        vm.roll(200000);

        uint256 curr_epoch = (block.number / 50064) + 1;
        uint256 lepoch = voting.getUser(address(1234)).lepoch;

        for (uint256 epoch = lepoch+1; epoch < curr_epoch; epoch++) {
            epochs.push(epoch);
        }

        uint len = epochs.length;

        hoax(address(1234));
        voting.claimReward(epochs);
        assertEq(voting.getUser(address(1234)).totalReward, 0, "vhot must not change");
        vm.stopPrank();

        for (uint256 i = 0; i < len; i++) {
            epochs.pop();
        }
        assertEq(epochs.length, 0, "epochs must return to original length");
    } 


    /// @notice will test penalise of a recommender
    /// @dev will register a candidate and a world ID, then the world ID will vote and the candidate will penalise them.
    function test_penalise_recommender() public {
        assertTrue(register_worldID_test("Michael", address(this)), "Could not sign up user");
                
        vm.prank(address(1234));
        assertTrue(register_candidate_test("Dwight", address(1234)));
        vm.stopPrank();
        
        vp.push(Worldcoin.VotingPair(address(1234), 100));
        
        voting.recommendCandidate(vp);

        // check that assigned weight of canidate = weight
        assertEq(voting.assignedWeight(address(1234)), 100, "incorrect weight assigned");
        // check that the voting pair in recommendee[msg.sender] is equal to that in vp
        assertEq(voting.getListOfRecommendees(address(this)).length, 1, "incorrect recommendee length");
        assertEq(voting.getListOfRecommendees(address(this))[0].weight, 100, "incorrect weight in recommendees");
        // check that the voting pair pushed in recommender[candidate] is that of msg.sender and 100
        assertEq(voting.getListOfRecommenders(address(1234)).length, 1, "incorrect recommendee length");
        assertEq(voting.getListOfRecommenders(address(1234))[0].weight, 100, "incorrect weight in recommendees");
        
        // return state to original version
        vp.pop();
        assertEq(vp.length, 0, "Voting pair[] pop did not work");

        Worldcoin.User memory voted_worldID_user = voting.getUser(address(this));
        assertEq(voted_worldID_user.vcold, 100, "vcold not increased");

        vm.prank(address(1234));
        voting.penalise(address(this));

        Worldcoin.User memory penalised_worldID_user = voting.getUser(address(this));
        assertEq(penalised_worldID_user.vcold, 0, "vcold not decreased");
    }

    /// @notice will test penalise of a world ID that is not a recommender
    /// @dev will register a candidate and a world ID, then the candidate will penalise them but it should revert.
    function test_penalise_no_vote() public {
        assertTrue(register_worldID_test("Michael", address(this)), "Could not sign up user");
                
        startHoax(address(1234));
        assertTrue(register_candidate_test("Dwight", address(1234)));
        vm.expectRevert("Given user is not a recommender");
        voting.penalise(address(this));
        vm.stopPrank();
    }



    /// @dev helper function to assert correct all the registration parameters
    /// @param _name - name of world ID user to be registered
    /// @param wID_addr - address world ID signed up with
    function register_worldID_test(string memory _name, address wID_addr) private returns (bool) {
        voting.registerAsWorldIDHolder( _name);
        Worldcoin.User memory user = voting.getUser(wID_addr);

        assertTrue(user.isWorldIDHolder, "Incorrect worldID holder");
        assertTrue(user.isRegistered, "Incorrect register");
        assertEq(user.vhot, 100, "Incorrect vhot");
        assertEq(user.vcold, 0, "Incorrect vcold");
        assertTrue(user.status == Worldcoin.Status.WorldIDHolder, "Incorrect worldID status");
        assertEq(user.totalReward, 0, "Incorrect total reward");

        return true;
    }

    /// @dev helper function to assert correct all the registration parameters
    /// @param _name - name of candidate user to be registered
    /// @param can_addr - address candidate signed up with
    function register_candidate_test(string memory _name, address can_addr) private returns (bool) {
        voting.registerAsCandidate(_name);
        
        Worldcoin.User memory user = voting.getUser(can_addr);

        assertEq(user.isWorldIDHolder, false, "Incorrect worldID holder");
        assertTrue(user.isRegistered, "Incorrect register");
        assertEq(user.vhot, 0, "Incorrect vhot");
        assertEq(user.vcold, 0, "Incorrect vcold");
        assertTrue(user.status == Worldcoin.Status.Candidate, "Incorrect worldID status");
        assertEq(user.totalReward, 0, "Incorrect total reward");

        return true;
    }
}