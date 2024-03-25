// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/abdk-libraries-solidity/ABDKMath64x64.sol";

contract ExponentialCalculator {
    function inversePower(uint256 x) public pure returns (uint) {
        // Represent the percentage as a fixed-point number.
        int128 percentage = ABDKMath64x64.divu(x, 100);

        // Calculate e^(percentage)
        int128 result = ABDKMath64x64.exp(percentage);

        // Multiply by 10^5 to keep 5 decimal places
        result = ABDKMath64x64.mul(result, ABDKMath64x64.fromUInt(10**5));

        // Invert the exponential as required
        result = ABDKMath64x64.div(ABDKMath64x64.fromUInt(10**5), result); 

        // Multiply by 10^5 to keep 5 decimal places
        result = ABDKMath64x64.mul(result, ABDKMath64x64.fromUInt(10**5));

        // Convert the fixed-point result to a uint and return it.
        return ABDKMath64x64.toUInt(result);
    }
}