// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title A Raffle Contract
 * @author Mohamed
 * @notice this contract for creating raffle
 * @dev Implements Chainlink VRF_v2
 */
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public {}

    function peckWinner() public {}

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
