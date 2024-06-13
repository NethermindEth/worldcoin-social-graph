// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Voting} from "../src/voting.sol";
import {verifyWorldID} from "../src/verifyWorldID.sol";
import {Worldcoin} from "../src/social_graph.sol";
import {DeployVoting} from "../scripts/voting.s.sol";

import {Test} from "../lib/forge-std/src/Test.sol";

/// @title Testing for social graph
contract SocialGraphTest is Test {
    Voting voting;
    Worldcoin.VotingPair[] vp;
    uint256[] epochs;
    string[13] names = ["Michael", "Jim", "Pam", "Dwight", "Kelly", "Ryan", "Phylis", "Stanley", "Creed", "Toby", "Angela", "Kevin", "Oscar"];

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
    function test_update_status_verified_7_wID_with_100_voting_power_each( address[7] memory addrs) public {        
        // ensure unique addresses
        vm.assume(msg.sender != addrs[0] && msg.sender != addrs[1] && msg.sender != addrs[2] && msg.sender != addrs[3] && msg.sender != addrs[4] && msg.sender != addrs[5] && msg.sender != addrs[6]);
        vm.assume(addrs[0] != addrs[1] && addrs[0] != addrs[2] && addrs[0] != addrs[3] && addrs[0] != addrs[4] && addrs[0] != addrs[5] && addrs[0] != addrs[6]);
        vm.assume(addrs[1] != addrs[0] && addrs[1] != addrs[2] && addrs[1] != addrs[3] && addrs[1] != addrs[4] && addrs[1] != addrs[5] && addrs[1] != addrs[6]);
        vm.assume(addrs[2] != addrs[0] && addrs[2] != addrs[1] && addrs[2] != addrs[3] && addrs[2] != addrs[4] && addrs[2] != addrs[5] && addrs[2] != addrs[6]);
        vm.assume(addrs[3] != addrs[0] && addrs[3] != addrs[1] && addrs[3] != addrs[2] && addrs[3] != addrs[4] && addrs[3] != addrs[5] && addrs[3] != addrs[6]);
        vm.assume(addrs[4] != addrs[0] && addrs[4] != addrs[1] && addrs[4] != addrs[2] && addrs[4] != addrs[3] && addrs[4] != addrs[5] && addrs[4] != addrs[6]);
        vm.assume(addrs[5] != addrs[0] && addrs[5] != addrs[1] && addrs[5] != addrs[2] && addrs[5] != addrs[3] && addrs[5] != addrs[4] && addrs[5] != addrs[6]);
        vm.assume(addrs[6] != addrs[0] && addrs[6] != addrs[1] && addrs[6] != addrs[2] && addrs[6] != addrs[3] && addrs[6] != addrs[4] && addrs[6] != addrs[5]);

        
        assertTrue(register_candidate_test("Andy", address(this)));
                
        for (uint256 i = 0; i < 7; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(Worldcoin.VotingPair(address(this), 100));
            voting.recommendCandidate(vp);
            (,,,uint256 vhot,,,,) = voting.users(addrs[i]);
            assertEq(vhot, 0, "User must have voted will all voting power");
            vm.stopPrank();
            vp.pop();
            assertEq(vp.length, 0, "Voting pair[] pop did not work");
        }

        voting.updateStatusVerified();

        (,,,uint256 vhot_can,uint256 vcold_can,Worldcoin.Status status_can,,) = voting.users(address(this));

        assertTrue(status_can == Worldcoin.Status.VerifiedIdentity, "Did not update status");
        assertEq(vhot_can, 96, "Did not update vhot");
        assertEq(vcold_can, 0, "Did not update vcold");
    
        for (uint i = 0; i < 7; i++) {
            (,,,uint256 vhot,,,,) = voting.users(addrs[i]);
            assertEq(vhot, 60, "wID voters must have restored correct voting power");
        }
    }

    /// @notice will test the update status function that it reverts if not voting power is not over threshold
    /// @dev will register 6 world IDs and vote with all their voting power but will revert as it is not enough
    /// voting power.
    function test_revert_update_status_verified_6_wID_with_100_voting_power_each( address[6] memory addrs) public {       
        // ensure unique addresses
        vm.assume(msg.sender != addrs[0] && msg.sender != addrs[1] && msg.sender != addrs[2] && msg.sender != addrs[3] && msg.sender != addrs[4] && msg.sender != addrs[5]);
        vm.assume(addrs[0] != addrs[1] && addrs[0] != addrs[2] && addrs[0] != addrs[3] && addrs[0] != addrs[4] && addrs[0] != addrs[5]);
        vm.assume(addrs[1] != addrs[0] && addrs[1] != addrs[2] && addrs[1] != addrs[3] && addrs[1] != addrs[4] && addrs[1] != addrs[5]);
        vm.assume(addrs[2] != addrs[0] && addrs[2] != addrs[1] && addrs[2] != addrs[3] && addrs[2] != addrs[4] && addrs[2] != addrs[5]);
        vm.assume(addrs[3] != addrs[0] && addrs[3] != addrs[1] && addrs[3] != addrs[2] && addrs[3] != addrs[4] && addrs[3] != addrs[5]);
        vm.assume(addrs[4] != addrs[0] && addrs[4] != addrs[1] && addrs[4] != addrs[2] && addrs[4] != addrs[3] && addrs[4] != addrs[5]);
        vm.assume(addrs[5] != addrs[0] && addrs[5] != addrs[1] && addrs[5] != addrs[2] && addrs[5] != addrs[3] && addrs[5] != addrs[4]);

        assertTrue(register_candidate_test("Andy", address(this)));
                
        for (uint256 i = 0; i < 6; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(Worldcoin.VotingPair(address(this), 100));
            voting.recommendCandidate(vp);
            (,,,uint256 vhot,,,,) = voting.users(addrs[i]);
            assertEq(vhot, 0, "User must have voted will all voting power");
            vm.stopPrank();
            vp.pop();
            assertEq(vp.length, 0, "Voting pair[] pop did not work");
        }

        // candidate calls update status
        vm.expectRevert("User should have higher power than threshold");
        voting.updateStatusVerified();
    }

    /// @notice will test the update status function to check that a candidate can become a verified identity
    /// @dev will register 13 world IDs and vote with half their voting power to overcome the threshold allowing 
    /// the can to become verified.
    function test_update_status_verified_13_wID_with_50_voting_power_each( address[13] memory addrs) public {
        // ensure unique addresses
        vm.assume(msg.sender != addrs[0] && msg.sender != addrs[1] && msg.sender != addrs[2] && msg.sender != addrs[3] && msg.sender != addrs[4] && msg.sender != addrs[5] && msg.sender != addrs[6] && msg.sender != addrs[7] && msg.sender != addrs[8] && msg.sender != addrs[9] && msg.sender != addrs[10] && msg.sender != addrs[11] && msg.sender != addrs[12]);
        vm.assume(addrs[0] != addrs[1] && addrs[0] != addrs[2] && addrs[0] != addrs[3] && addrs[0] != addrs[4] && addrs[0] != addrs[5] && addrs[0] != addrs[6] && addrs[0] != addrs[7] && addrs[0] != addrs[8] && addrs[0] != addrs[9] && addrs[0] != addrs[10] && addrs[0] != addrs[11] && addrs[0] != addrs[12]);
        vm.assume(addrs[1] != addrs[0] && addrs[1] != addrs[2] && addrs[1] != addrs[3] && addrs[1] != addrs[4] && addrs[1] != addrs[5] && addrs[1] != addrs[6] && addrs[1] != addrs[7] && addrs[1] != addrs[8] && addrs[1] != addrs[9] && addrs[1] != addrs[10] && addrs[1] != addrs[11] && addrs[1] != addrs[12]);
        vm.assume(addrs[2] != addrs[0] && addrs[2] != addrs[1] && addrs[2] != addrs[3] && addrs[2] != addrs[4] && addrs[2] != addrs[5] && addrs[2] != addrs[6] && addrs[2] != addrs[7] && addrs[2] != addrs[8] && addrs[2] != addrs[9] && addrs[2] != addrs[10] && addrs[2] != addrs[11] && addrs[2] != addrs[12]);
        vm.assume(addrs[3] != addrs[0] && addrs[3] != addrs[1] && addrs[3] != addrs[2] && addrs[3] != addrs[4] && addrs[3] != addrs[5] && addrs[3] != addrs[6] && addrs[3] != addrs[7] && addrs[3] != addrs[8] && addrs[3] != addrs[9] && addrs[3] != addrs[10] && addrs[3] != addrs[11] && addrs[3] != addrs[12]);
        vm.assume(addrs[4] != addrs[0] && addrs[4] != addrs[1] && addrs[4] != addrs[2] && addrs[4] != addrs[3] && addrs[4] != addrs[5] && addrs[4] != addrs[6] && addrs[4] != addrs[7] && addrs[4] != addrs[8] && addrs[4] != addrs[9] && addrs[4] != addrs[10] && addrs[4] != addrs[11] && addrs[4] != addrs[12]);
        vm.assume(addrs[5] != addrs[0] && addrs[5] != addrs[1] && addrs[5] != addrs[2] && addrs[5] != addrs[3] && addrs[5] != addrs[4] && addrs[5] != addrs[6] && addrs[5] != addrs[7] && addrs[5] != addrs[8] && addrs[5] != addrs[9] && addrs[5] != addrs[10] && addrs[5] != addrs[11] && addrs[5] != addrs[12]);
        vm.assume(addrs[6] != addrs[0] && addrs[6] != addrs[1] && addrs[6] != addrs[2] && addrs[6] != addrs[3] && addrs[6] != addrs[4] && addrs[6] != addrs[5] && addrs[6] != addrs[7] && addrs[6] != addrs[8] && addrs[6] != addrs[9] && addrs[6] != addrs[10] && addrs[6] != addrs[11] && addrs[6] != addrs[12]);
        vm.assume(addrs[7] != addrs[0] && addrs[7] != addrs[1] && addrs[7] != addrs[2] && addrs[7] != addrs[3] && addrs[7] != addrs[4] && addrs[7] != addrs[5] && addrs[7] != addrs[6] && addrs[7] != addrs[8] && addrs[7] != addrs[9] && addrs[7] != addrs[10] && addrs[7] != addrs[11] && addrs[7] != addrs[12]);
        vm.assume(addrs[8] != addrs[0] && addrs[8] != addrs[1] && addrs[8] != addrs[2] && addrs[8] != addrs[3] && addrs[8] != addrs[4] && addrs[8] != addrs[5] && addrs[8] != addrs[6] && addrs[8] != addrs[7] && addrs[8] != addrs[9] && addrs[8] != addrs[10] && addrs[8] != addrs[11] && addrs[8] != addrs[12]);
        vm.assume(addrs[9] != addrs[0] && addrs[9] != addrs[1] && addrs[9] != addrs[2] && addrs[9] != addrs[3] && addrs[9] != addrs[4] && addrs[9] != addrs[5] && addrs[9] != addrs[6] && addrs[9] != addrs[7] && addrs[9] != addrs[8] && addrs[9] != addrs[10] && addrs[9] != addrs[11] && addrs[9] != addrs[12]);
        vm.assume(addrs[10] != addrs[0] && addrs[10] != addrs[1] && addrs[10] != addrs[2] && addrs[10] != addrs[3] && addrs[10] != addrs[4] && addrs[10] != addrs[5] && addrs[10] != addrs[6] && addrs[10] != addrs[7] && addrs[10] != addrs[8] && addrs[10] != addrs[9] && addrs[10] != addrs[11] && addrs[10] != addrs[12]);
        vm.assume(addrs[11] != addrs[0] && addrs[11] != addrs[1] && addrs[11] != addrs[2] && addrs[11] != addrs[3] && addrs[11] != addrs[4] && addrs[11] != addrs[5] && addrs[11] != addrs[6] && addrs[11] != addrs[7] && addrs[11] != addrs[8] && addrs[11] != addrs[9] && addrs[11] != addrs[10] && addrs[11] != addrs[12]);
        vm.assume(addrs[12] != addrs[0] && addrs[12] != addrs[1] && addrs[12] != addrs[2] && addrs[12] != addrs[3] && addrs[12] != addrs[4] && addrs[12] != addrs[5] && addrs[12] != addrs[6] && addrs[12] != addrs[7] && addrs[12] != addrs[8] && addrs[12] != addrs[9] && addrs[12] != addrs[10] && addrs[12] != addrs[11]);

        assertTrue(register_candidate_test("Andy", address(this)));

        for (uint256 i = 0; i < 13; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(Worldcoin.VotingPair(address(this), 50));
            voting.recommendCandidate(vp);
            (,,,uint256 vhot,,,,) = voting.users(addrs[i]);
            assertEq(vhot, 50, "User must have voted will half their voting power");
            vm.stopPrank();
            vp.pop();
            assertEq(vp.length, 0, "Voting pair[] pop did not work");
        }

        // candidate calls update status
        voting.updateStatusVerified();
        (,,,uint256 vhot_can, uint256 vcold_can, Worldcoin.Status status_can,,) = voting.users(address(this));
        assertTrue(status_can == Worldcoin.Status.VerifiedIdentity, "Did not update status");
        assertEq(vhot_can, 96, "Did not update status");
        assertEq(vcold_can, 0, "Did not update status");
    }

    /// @notice will test the claim function when the candidate has become verifed and the world ID claims its rewards
    /// @dev will register 7 world IDs and vote with all their voting power to overcome the threshold allowing 
    /// the can to become verified, will call the update status and then the claim.
    function test_claim_candidate_is_verified( address[7] memory addrs) public {
        // ensure unique addresses
        vm.assume(msg.sender != addrs[0] && msg.sender != addrs[1] && msg.sender != addrs[2] && msg.sender != addrs[3] && msg.sender != addrs[4] && msg.sender != addrs[5] && msg.sender != addrs[6]);
        vm.assume(addrs[0] != addrs[1] && addrs[0] != addrs[2] && addrs[0] != addrs[3] && addrs[0] != addrs[4] && addrs[0] != addrs[5] && addrs[0] != addrs[6]);
        vm.assume(addrs[1] != addrs[0] && addrs[1] != addrs[2] && addrs[1] != addrs[3] && addrs[1] != addrs[4] && addrs[1] != addrs[5] && addrs[1] != addrs[6]);
        vm.assume(addrs[2] != addrs[0] && addrs[2] != addrs[1] && addrs[2] != addrs[3] && addrs[2] != addrs[4] && addrs[2] != addrs[5] && addrs[2] != addrs[6]);
        vm.assume(addrs[3] != addrs[0] && addrs[3] != addrs[1] && addrs[3] != addrs[2] && addrs[3] != addrs[4] && addrs[3] != addrs[5] && addrs[3] != addrs[6]);
        vm.assume(addrs[4] != addrs[0] && addrs[4] != addrs[1] && addrs[4] != addrs[2] && addrs[4] != addrs[3] && addrs[4] != addrs[5] && addrs[4] != addrs[6]);
        vm.assume(addrs[5] != addrs[0] && addrs[5] != addrs[1] && addrs[5] != addrs[2] && addrs[5] != addrs[3] && addrs[5] != addrs[4] && addrs[5] != addrs[6]);
        vm.assume(addrs[6] != addrs[0] && addrs[6] != addrs[1] && addrs[6] != addrs[2] && addrs[6] != addrs[3] && addrs[6] != addrs[4] && addrs[6] != addrs[5]);
        
        assertTrue(register_candidate_test("Andy", address(this)));

        for (uint256 i = 0; i < 7; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(Worldcoin.VotingPair(address(this), 100));
            voting.recommendCandidate(vp);
            (,,,uint256 vhot,,,,) = voting.users(addrs[i]);
            assertEq(vhot, 0, "User must have voted will all voting power");
            vm.stopPrank();
            vp.pop();
            assertEq(vp.length, 0, "Voting pair[] pop did not work");
        }

        // candidate calls update status
        voting.updateStatusVerified();
        (,,,uint256 vhot_can, uint256 vcold_can, Worldcoin.Status status_can,,) = voting.users(address(this));
        assertTrue(status_can == Worldcoin.Status.VerifiedIdentity, "Did not update status");
        assertEq(vhot_can, 96, "Did not update status");
        assertEq(vcold_can, 0, "Did not update status");
    
        // check vhot of wID voters

        for (uint256 i = 0; i < 7; i++) {
            (,,,uint256 vhot_user,,,uint256 total_reward_user,) = voting.users(addrs[i]);
            assertEq(vhot_user, 60, "wID voters must have restored correct voting power");
            assertEq(total_reward_user, 0, "initial total reward must be 0");
        }

        vm.roll(200000);
        uint256 curr_epoch = (block.number / 50064) + 1;

        (,,,,,,, uint256 lepoch) = voting.users(addrs[0]);

        for (uint256 epoch = lepoch+1; epoch < curr_epoch; epoch++) {
            epochs.push(epoch);
        }

        uint len = epochs.length;

        vm.prank(addrs[0]);
        voting.claimReward(epochs);
        (,,,,,,uint256 final_total_reward,) = voting.users(addrs[0]);
        assertEq(final_total_reward, 20000, "Total reward must be correctly computed");

        for (uint256 i = 0; i < len; i++) {
            epochs.pop();
        }
        assertEq(epochs.length, 0, "epochs must return to original length");
    } 

    /// @notice will test claim function when the candidate has not become verifed and the world ID claims its rewards
    /// @dev will register 7 world IDs and vote with all their voting power to overcome the threshold allowing the
    /// candidate to become verified, will call the update status and then the claim but the rewards must not change.
    function test_claim_candidate_is_not_verified( address[7] memory addrs) public {
        // ensure unique addresses
        vm.assume(msg.sender != addrs[0] && msg.sender != addrs[1] && msg.sender != addrs[2] && msg.sender != addrs[3] && msg.sender != addrs[4] && msg.sender != addrs[5] && msg.sender != addrs[6]);
        vm.assume(addrs[0] != addrs[1] && addrs[0] != addrs[2] && addrs[0] != addrs[3] && addrs[0] != addrs[4] && addrs[0] != addrs[5] && addrs[0] != addrs[6]);
        vm.assume(addrs[1] != addrs[0] && addrs[1] != addrs[2] && addrs[1] != addrs[3] && addrs[1] != addrs[4] && addrs[1] != addrs[5] && addrs[1] != addrs[6]);
        vm.assume(addrs[2] != addrs[0] && addrs[2] != addrs[1] && addrs[2] != addrs[3] && addrs[2] != addrs[4] && addrs[2] != addrs[5] && addrs[2] != addrs[6]);
        vm.assume(addrs[3] != addrs[0] && addrs[3] != addrs[1] && addrs[3] != addrs[2] && addrs[3] != addrs[4] && addrs[3] != addrs[5] && addrs[3] != addrs[6]);
        vm.assume(addrs[4] != addrs[0] && addrs[4] != addrs[1] && addrs[4] != addrs[2] && addrs[4] != addrs[3] && addrs[4] != addrs[5] && addrs[4] != addrs[6]);
        vm.assume(addrs[5] != addrs[0] && addrs[5] != addrs[1] && addrs[5] != addrs[2] && addrs[5] != addrs[3] && addrs[5] != addrs[4] && addrs[5] != addrs[6]);
        vm.assume(addrs[6] != addrs[0] && addrs[6] != addrs[1] && addrs[6] != addrs[2] && addrs[6] != addrs[3] && addrs[6] != addrs[4] && addrs[6] != addrs[5]);
        assertTrue(register_candidate_test("Andy", address(this)));

        for (uint256 i = 0; i < 7; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(Worldcoin.VotingPair(address(this), 100));
            voting.recommendCandidate(vp);
            (,,,uint256 vhot,,,,) = voting.users(addrs[i]);
            assertEq(vhot, 0, "User must have voted will all voting power");
            vm.stopPrank();
            vp.pop();
            assertEq(vp.length, 0, "Voting pair[] pop did not work");
        }


        vm.roll(200000);
        uint256 curr_epoch = (block.number / 50064) + 1;

        (,,,,,,, uint256 lepoch) = voting.users(addrs[0]);

        for (uint256 epoch = lepoch+1; epoch < curr_epoch; epoch++) {
            epochs.push(epoch);
        }

        uint len = epochs.length;

        vm.prank(addrs[0]);
        voting.claimReward(epochs);
        (,,,,,,uint256 final_total_reward,) = voting.users(addrs[0]);
        assertEq(final_total_reward, 0, "Total reward must not change");

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

        (,,,,uint256 vcold_worldID,,,) = voting.users(address(this));
        assertEq(vcold_worldID, 100, "vcold not increased");

        vm.prank(address(1234));
        voting.penalise(address(this));

        (,,,,uint256 vcold_penalised_worldID,,,) = voting.users(address(this));
        assertEq(vcold_penalised_worldID, 0, "vcold not decreased");
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
        (string memory name ,bool isWorldIDHolder, bool isRegistered, uint256 vhot, uint256 vcold, Worldcoin.Status status, uint256 totalReward, uint256 lepoch) = voting.users(wID_addr);

        assertTrue(isWorldIDHolder, "Incorrect worldID holder");
        assertTrue(isRegistered, "Incorrect register");
        assertEq(vhot, 100, "Incorrect vhot");
        assertEq(vcold, 0, "Incorrect vcold");
        assertTrue(status == Worldcoin.Status.WorldIDHolder, "Incorrect worldID status");
        assertEq(totalReward, 0, "Incorrect total reward");

        return true;
    }

    /// @dev helper function to assert correct all the registration parameters
    /// @param _name - name of candidate user to be registered
    /// @param can_addr - address candidate signed up with
    function register_candidate_test(string memory _name, address can_addr) private returns (bool) {
        voting.registerAsCandidate(_name);
        
        (string memory name ,bool isWorldIDHolder, bool isRegistered, uint256 vhot, uint256 vcold, Worldcoin.Status status, uint256 totalReward, uint256 lepoch) = voting.users(can_addr);

        assertEq(isWorldIDHolder, false, "Incorrect worldID holder");
        assertTrue(isRegistered, "Incorrect register");
        assertEq(vhot, 0, "Incorrect vhot");
        assertEq(vcold, 0, "Incorrect vcold");
        assertTrue(status == Worldcoin.Status.Candidate, "Incorrect worldID status");
        assertEq(totalReward, 0, "Incorrect total reward");

        return true;
    }
}