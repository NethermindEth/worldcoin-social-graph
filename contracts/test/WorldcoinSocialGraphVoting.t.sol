// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import { WorldcoinSocialGraphVoting } from "../src/WorldcoinSocialGraphVoting.sol";
import { WorldcoinVerifier } from "../src/WorldcoinVerifier.sol";
import { WorldcoinSocialGraphStorage } from "../src/WorldcoinSocialGraphStorage.sol";
import { IWorldcoinSocialGraphStorage } from "../src/interfaces/IWorldcoinSocialGraphStorage.sol";
import { DeployVoting } from "../scripts/voting.s.sol";
import { WorldcoinSocialGraphTestUtil } from "./Utils.sol";

/// @title Testing for social graph
contract WorldcoinSocialGraphVotingTest is WorldcoinSocialGraphTestUtil {
    IWorldcoinSocialGraphStorage.VotingPair[] vp;
    uint256[] epochs;
    string[13] names = [
        "Michael",
        "Jim",
        "Pam",
        "Dwight",
        "Kelly",
        "Ryan",
        "Phylis",
        "Stanley",
        "Creed",
        "Toby",
        "Angela",
        "Kevin",
        "Oscar"
    ];
    /// @notice will create a new voting contract for each test

    function setUp() public {
        setupContracts();
    }

    /// @notice will test the worldID registration function
    function test_worldID_register() public {
        register_worldID_test("Jim", address(this));
    }

    /// @notice Tests the registration of a candidate.
    /// @dev This function calls `register_candidate_test` with a sample name and address, and asserts the registration
    /// was successful.
    function test_candidate_register() public {
        register_candidate_test("Pam", address(this));
    }

    /// @notice Tests the registration of a candidate and expects a revert if the same sender tries to register again.
    /// @dev This function first registers a candidate and then attempts to register the same candidate again to trigger
    /// a revert.
    function test_revert_register_can_for_same_sender() public {
        register_candidate_test("Pam", address(this));
        vm.expectRevert("WorldcoinGraph: ALREADY_REGISTERED");
        register_candidate_test("Pam", address(this));
    }

    /// @notice Tests the registration of a World ID and expects a revert if the same sender tries to register again.
    /// @dev This function first registers a World ID and then attempts to register the same World ID again to trigger a
    /// revert.
    function test_revert_register_wID_for_same_sender() public {
        register_worldID_test("Jim", address(this));
        vm.expectRevert("WorldcoinGraph: ALREADY_REGISTERED");
        register_worldID_test("Jim", address(this));
    }

    /// @notice Tests the voting of a candidate by a world ID where they have both correctly registered.
    /// @dev First will register the world ID and the candidate then will recommend the candidate with vote weight of
    /// 100 (i.e. all its weight).
    function test_vote_for_1() public {
        register_worldID_test("Michael", address(this));

        vm.prank(address(1234));
        register_candidate_test("Dwight", address(1234));
        vm.stopPrank();

        vp.push(IWorldcoinSocialGraphStorage.VotingPair(address(1234), 100));

        voting.recommendCandidates(vp);

        // check that assigned weight of canidate = weight
        assertEq(voting.assignedWeight(address(1234)), 100, "incorrect weight assigned");
        // check that the voting pair in recommendee[msg.sender] is equal to that in vp
        assertEq(voting.getListOfRecommendees(address(this)).length, 1, "incorrect recommendee length");
        assertEq(voting.getListOfRecommendees(address(this))[0].weight, 100, "incorrect weight in recommendees");
        // check that the voting pair pushed in recommender[candidate] is that of msg.sender and 100
        assertEq(voting.getListOfRecommenders(address(1234)).length, 1, "incorrect recommendee length");
        assertEq(voting.getListOfRecommenders(address(1234))[0].weight, 100, "incorrect weight in recommendees");
        assertEq(voting.getListOfRecommenders(address(1234))[0].user, address(this), "incorrect weight in recommendees");
    }
    /// @notice Tests the voting process with an incorrect candidate address and expects a revert.
    /// @dev This function registers a World ID user and then attempts to vote with a fake candidate address.

    function test_revert_vote_incorrect_candidate(address fake_can_addr) public {
        register_worldID_test("Michael", address(this));

        vp.push(IWorldcoinSocialGraphStorage.VotingPair(fake_can_addr, 100));
        vm.expectRevert();
        voting.recommendCandidates(vp);
    }

    /// @notice Tests the voting process when the World ID is not registered and expects a revert.
    /// @dev This function attempts to vote without registering the World ID, expecting the `recommendCandidates`
    /// function to revert with the message "WorldcoinGraph: INVALID_VOTER".
    function test_revert_vote_wID_not_registered(address fake_can_addr) public {
        // Note: Here since the address calling the function is not signed up we can just call recommend

        vp.push(IWorldcoinSocialGraphStorage.VotingPair(fake_can_addr, 100));
        vm.expectRevert("WorldcoinGraph: INVALID_VOTER");
        voting.recommendCandidates(vp);
    }

    /// @notice Tests the voting process by a registered candidate and expects a revert.
    /// @dev This function registers a candidate and then attempts to vote, expecting the `recommendCandidates` function
    /// to revert with the message "WorldcoinGraph: INVALID_VOTER".
    function test_revert_candidate_vote(address fake_can_addr) public {
        register_candidate_test("Ross", address(this));

        vp.push(IWorldcoinSocialGraphStorage.VotingPair(fake_can_addr, 100));
        vm.expectRevert("WorldcoinGraph: INVALID_VOTER");
        voting.recommendCandidates(vp);
    }

    /// @notice will test the update status function to check that a candidate can become a verified identity
    /// @dev will register 7 world IDs and vote with all their voting power to overcome the threshold allowing
    /// the can to become verified.
    function test_update_status_verified_7_wID_with_100_voting_power_each(address[7] memory addrs) public {
        // Ensure unique addresses, not zero addresses, and not equal to msg.sender
        for (uint256 i = 0; i < 7; i++) {
            vm.assume(addrs[i] != address(0));
            vm.assume(addrs[i] != msg.sender);
            vm.assume(addrs[i] != address(this));
            for (uint256 j = i + 1; j < 7; j++) {
                vm.assume(addrs[i] != addrs[j]);
            }
        }
        register_candidate_test("Andy", address(this));

        for (uint256 i = 0; i < 7; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(IWorldcoinSocialGraphStorage.VotingPair(address(this), 100));
            voting.recommendCandidates(vp);
            (, uint256 vhot,,,) = voting.users(addrs[i]);
            assertEq(vhot, 0, "User must have voted will all voting power");
            vm.stopPrank();
            vp.pop();
        }

        voting.updateStatusVerified();

        (, uint256 vhot_can, uint256 vcold_can, IWorldcoinSocialGraphStorage.Status status_can,) =
            voting.users(address(this));

        assertTrue(status_can == IWorldcoinSocialGraphStorage.Status.VERIFIED_IDENTITY, "Did not update status");
        assertEq(vhot_can, 96, "Did not update vhot");
        assertEq(vcold_can, 0, "Did not update vcold");

        for (uint256 i = 0; i < 7; i++) {
            (, uint256 vhot,,,) = voting.users(addrs[i]);
            assertEq(vhot, 60, "wID voters must have restored correct voting power");
        }
    }

    /// @notice will test the update status function that it reverts if not voting power is not over threshold
    /// @dev will register 6 world IDs and vote with all their voting power but will revert as it is not enough
    /// voting power.
    function test_revert_update_status_verified_6_wID_with_100_voting_power_each(address[6] memory addrs) public {
        // Ensure unique addresses, not zero addresses, and not equal to msg.sender
        for (uint256 i = 0; i < 6; i++) {
            vm.assume(addrs[i] != address(0));
            vm.assume(addrs[i] != msg.sender);
            vm.assume(addrs[i] != address(this));
            for (uint256 j = i + 1; j < 6; j++) {
                vm.assume(addrs[i] != addrs[j]);
            }
        }

        register_candidate_test("Andy", address(this));

        for (uint256 i = 0; i < 6; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(IWorldcoinSocialGraphStorage.VotingPair(address(this), 100));
            voting.recommendCandidates(vp);
            (, uint256 vhot,,,) = voting.users(addrs[i]);
            assertEq(vhot, 0, "User must have voted will all voting power");
            vm.stopPrank();
            vp.pop();
        }

        // candidate calls update status
        vm.expectRevert("WorldcoinGraph: INSUFFICIENT_VOTING_POWER");
        voting.updateStatusVerified();
    }

    /// @notice will test the update status function to check that a candidate can become a verified identity
    /// @dev will register 13 world IDs and vote with half their voting power to overcome the threshold allowing
    /// the can to become verified.
    function test_update_status_verified_13_wID_with_50_voting_power_each(address[13] memory addrs) public {
        // ensure unique addresses
        // Ensure unique addresses, not zero addresses, and not equal to msg.sender
        for (uint256 i = 0; i < 13; i++) {
            vm.assume(addrs[i] != address(0));
            vm.assume(addrs[i] != msg.sender);
            vm.assume(addrs[i] != address(this));
            for (uint256 j = i + 1; j < 13; j++) {
                vm.assume(addrs[i] != addrs[j]);
            }
        }
        register_candidate_test("Andy", address(this));

        for (uint256 i = 0; i < 13; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(IWorldcoinSocialGraphStorage.VotingPair(address(this), 50));
            voting.recommendCandidates(vp);
            (, uint256 vhot,,,) = voting.users(addrs[i]);
            assertEq(vhot, 50, "User must have voted will half their voting power");
            vm.stopPrank();
            vp.pop();
        }

        // candidate calls update status
        voting.updateStatusVerified();
        (, uint256 vhot_can, uint256 vcold_can, IWorldcoinSocialGraphStorage.Status status_can,) =
            voting.users(address(this));
        assertTrue(status_can == IWorldcoinSocialGraphStorage.Status.VERIFIED_IDENTITY, "Did not update status");
        assertEq(vhot_can, 96, "Did not update status");
        assertEq(vcold_can, 0, "Did not update status");
    }

    /// @notice will test the claim function when the candidate has become verifed and the world ID claims its rewards
    /// @dev will register 7 world IDs and vote with all their voting power to overcome the threshold allowing
    /// the can to become verified, will call the update status and then the claim.
    function test_claim_candidate_is_verified(address[7] memory addrs) public {
        // ensure unique addresses
        // Ensure unique addresses, not zero addresses, and not equal to msg.sender
        for (uint256 i = 0; i < 7; i++) {
            vm.assume(addrs[i] != address(0));
            vm.assume(addrs[i] != msg.sender);
            vm.assume(addrs[i] != address(this));
            for (uint256 j = i + 1; j < 7; j++) {
                vm.assume(addrs[i] != addrs[j]);
            }
        }

        register_candidate_test("Andy", address(this));

        for (uint256 i = 0; i < 7; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(IWorldcoinSocialGraphStorage.VotingPair(address(this), 100));
            voting.recommendCandidates(vp);
            (, uint256 vhot,,,) = voting.users(addrs[i]);
            assertEq(vhot, 0, "User must have voted will all voting power");
            vm.stopPrank();
            vp.pop();
        }

        // candidate calls update status
        voting.updateStatusVerified();
        (, uint256 vhot_can, uint256 vcold_can, IWorldcoinSocialGraphStorage.Status status_can,) =
            voting.users(address(this));
        assertTrue(status_can == IWorldcoinSocialGraphStorage.Status.VERIFIED_IDENTITY, "Did not update status");
        assertEq(vhot_can, 96, "Did not update status");
        assertEq(vcold_can, 0, "Did not update status");

        // check vhot of wID voters

        for (uint256 i = 0; i < 7; i++) {
            (, uint256 vhot_user,,, uint256 total_reward_user) = voting.users(addrs[i]);
            assertEq(vhot_user, 60, "wID voters must have restored correct voting power");
            assertEq(total_reward_user, 0, "initial total reward must be 0");
        }

        vm.roll(200_000);
        uint256 curr_epoch = (block.number / 50_064) + 1;

        for (uint256 epoch = 1; epoch < curr_epoch; epoch++) {
            epochs.push(epoch);
        }

        uint256 len = epochs.length;

        vm.prank(addrs[0]);
        voting.claimReward(epochs);
        (,,,, uint256 final_total_reward) = voting.users(addrs[0]);
        assertEq(final_total_reward, 20_000, "Total reward must be correctly computed");

        for (uint256 i = 0; i < len; i++) {
            epochs.pop();
        }
        assertEq(epochs.length, 0, "epochs must return to original length");
    }

    /// @notice will test claim function when the candidate has not become verifed and the world ID claims its rewards
    /// @dev will register 7 world IDs and vote with all their voting power to overcome the threshold allowing the
    /// candidate to become verified, will call the update status and then the claim but the rewards must not change.
    function test_claim_candidate_is_not_verified(address[7] memory addrs) public {
        // Ensure unique addresses, not zero addresses, and not equal to msg.sender
        for (uint256 i = 0; i < 7; i++) {
            vm.assume(addrs[i] != address(0));
            vm.assume(addrs[i] != msg.sender);
            vm.assume(addrs[i] != address(this));
            for (uint256 j = i + 1; j < 7; j++) {
                vm.assume(addrs[i] != addrs[j]);
            }
        }

        register_candidate_test("Andy", address(this));

        for (uint256 i = 0; i < 7; i++) {
            startHoax(addrs[i]);
            register_worldID_test(names[i], addrs[i]);
            vp.push(IWorldcoinSocialGraphStorage.VotingPair(address(this), 100));
            voting.recommendCandidates(vp);
            (, uint256 vhot,,,) = voting.users(addrs[i]);
            assertEq(vhot, 0, "User must have voted with all voting power");
            vm.stopPrank();
            vp.pop();
        }

        vm.roll(200_000);
        uint256 curr_epoch = (block.number / 50_064) + 1;

        for (uint256 epoch = 1; epoch < curr_epoch; epoch++) {
            epochs.push(epoch);
        }

        vm.prank(addrs[0]);
        voting.claimReward(epochs);
        (,,,, uint256 final_total_reward) = voting.users(addrs[0]);
        assertEq(final_total_reward, 0, "Total reward must not change");

        epochs = new uint256[](0);
    }

    /// @notice will test penalise of a recommender
    /// @dev will register a candidate and a world ID, then the world ID will vote and the candidate will penalise them.
    function test_penalise_recommender() public {
        register_worldID_test("Michael", address(this));

        vm.prank(address(1234));
        register_candidate_test("Dwight", address(1234));
        vm.stopPrank();

        vp.push(IWorldcoinSocialGraphStorage.VotingPair(address(1234), 100));

        voting.recommendCandidates(vp);

        // check that assigned weight of canidate = weight
        assertEq(voting.assignedWeight(address(1234)), 100, "incorrect weight assigned");
        // check that the voting pair in recommendee[msg.sender] is equal to that in vp
        assertEq(voting.getListOfRecommendees(address(this)).length, 1, "incorrect recommendee length");
        assertEq(voting.getListOfRecommendees(address(this))[0].weight, 100, "incorrect weight in recommendees");
        // check that the voting pair pushed in recommender[candidate] is that of msg.sender and 100
        assertEq(voting.getListOfRecommenders(address(1234)).length, 1, "incorrect recommendee length");
        assertEq(voting.getListOfRecommenders(address(1234))[0].weight, 100, "incorrect weight in recommendees");

        (,, uint256 vcold_worldID,,) = voting.users(address(this));
        assertEq(vcold_worldID, 100, "vcold not increased");

        vm.prank(address(1234));
        voting.penalise(address(this));

        (,, uint256 vcold_penalised_worldID,,) = voting.users(address(this));
        assertEq(vcold_penalised_worldID, 0, "vcold not decreased");
    }

    /// @notice will test penalise of a world ID that is not a recommender
    /// @dev will register a candidate and a world ID, then the candidate will penalise them but it should revert.
    function test_penalise_no_vote() public {
        register_worldID_test("Michael", address(this));

        startHoax(address(1234));
        register_candidate_test("Dwight", address(1234));
        vm.expectRevert("WorldcoinGraph: RECOMMENDER_NOT_FOUND");
        voting.penalise(address(this));
        vm.stopPrank();
    }

    function test_InversePower() public view {
        // Match against manually calculated values
        assertEq(voting.inversePower(1), 99_004, "inversePower(1) should return 99004");
        assertEq(voting.inversePower(100), 36_787, "inversePower(100) should return 36787");
        assertEq(voting.inversePower(200), 13_533, "inversePower(200) should return 13533");
        assertEq(voting.inversePower(50), 60_653, "inversePower(50) should return 60653");
        assertEq(voting.inversePower(0), 100_000, "inversePower(0) should return 100000");
    }

    function testFuzz_InversePower(uint256 input) public view {
        input = bound(input, 1, 1000);
        uint256 result = voting.inversePower(input);
        assertLe(result, 100_000, "inversePower should return a value less than or equal to 100000");
    }
}
