// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { WorldcoinVerifier } from "../../src/WorldcoinVerifier.sol";
import { WorldcoinSocialGraphStorage } from "../../src/WorldcoinSocialGraphStorage.sol";
import { WorldcoinSocialGraphVoting } from "../../src/WorldcoinSocialGraphVoting.sol";
import { IWorldcoinVerifier } from "../../src/interfaces/IWorldcoinVerifier.sol";

contract WorldcoinVerifierMock is IWorldcoinVerifier {
    function verifyAndExecute(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    )
        public
        override
    { }
}
