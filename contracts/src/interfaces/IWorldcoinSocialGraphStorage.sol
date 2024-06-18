// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

interface IWorldcoinSocialGraphStorage {
    enum Status {
        UNREGISTERED,
        WORLD_ID_HOLDER,
        CANDIDATE,
        VERIFIED_IDENTITY
    }

    struct VotingPair {
        address user;
        uint256 weight;
    }

    struct User {
        string name;
        uint256 vhot;
        uint256 vcold;
        Status status;
        uint256 totalReward;
    }

    /// @notice Retrieves the total amount of voting power allocated to the candidates for a specific epoch.
    /// @param epoch The epoch for which to retrieve the distributed voting power.
    /// @return The total distributed voting power for the specified epoch.
    function rewardsPerEpoch(uint256 epoch) external view returns (uint256);

    /// @notice Retrieves the weight assigned by a user to users that become verified in a specific epoch.
    /// @param user The address of the user.
    /// @param epoch The epoch for which to retrieve the user's assigned weights.
    /// @return The weight assigned by the user for the specified epoch.
    function userEpochWeights(address user, uint256 epoch) external view returns (uint256);

    /// @notice Retrieves the total weight assigned to a candidate user.
    /// @param user The address of the candidate user.
    /// @return The total weight assigned to the candidate user.
    function assignedWeight(address user) external view returns (uint256);
}
