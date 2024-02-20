// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExponentialCalculator {
    function factorial(uint256 n) internal pure returns (uint256) {
        if (n == 0) return 1;
        uint256 result = 1;
        for (uint256 i = 1; i <= n; i++) {
            result *= i;
        }
        return result;
    }
    
    function power(uint256 base, uint256 exponent) internal pure returns (uint256) {
        uint256 result = 1;
        for (uint256 i = 0; i < exponent; i++) {
            result *= base;
        }
        return result;
    }

    function numDigits(uint256 number) internal pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    function calculateReverseExp(uint256 n) public pure returns (uint256) {
        uint256 result = 1000; // Initialize with 1.00
        uint256 factor = 1000; // Adjusting factor for decimal places
        for (uint256 i = 1; i <= 20; i++) { // Approximate up to 10th term of Taylor series
            result += (power(n, i) * factor) / factorial(i);
        }
        //TODO
        result =  1000 * 10**16/result;
        return result;
    }

}
