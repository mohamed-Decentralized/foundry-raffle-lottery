// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

library Check {
    function getExistPlayer(
        address _player,
        address payable[] memory players
    ) internal pure returns (int256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == _player) {
                return int256(i);
            }
        }
        return -1;
    }
}
