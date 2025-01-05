// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {Check} from "../src/Library.sol";

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    using Check for address;

    error Raffle__NotEnoughETH();
    error Raffle__PlayerAlreadyExists();
    error Raffle__TimeElapsed();
    error Raffle__RaffleNotReady();
    error Raffle_TransferFailed();
    error Raffle__RaffleUpKeepNeeded(
        uint256 playersLength,
        uint256 raffleBalance,
        uint256 raffleState
    );

    enum RaffleState {
        OPEN,
        PROCESS
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_intervalInSeconds;

    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NO_OF_WORDS = 1;

    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subId,
        uint32 callbackGasLimit,
        uint256 entranceFee,
        uint256 intervalInSeconds
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subId = subId;
        i_callbackGasLimit = callbackGasLimit;

        i_entranceFee = entranceFee;
        i_intervalInSeconds = intervalInSeconds;

        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotReady();
        }
        // if (block.timestamp >= s_lastTimeStamp + i_intervalInSeconds) {
        //     revert Raffle__TimeElapsed();
        // }
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETH();
        }
        if (msg.sender.getExistPlayer(s_players) == -1) {
            revert Raffle__PlayerAlreadyExists();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory performData) {
        bool timesUp = block.timestamp > s_lastTimeStamp + i_intervalInSeconds;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        bool raffleOpen = s_raffleState == RaffleState.OPEN;
        upkeepNeeded = raffleOpen && timesUp && hasPlayers && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /*performData*/) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__RaffleUpKeepNeeded(
                s_players.length,
                address(this).balance,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.PROCESS;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NO_OF_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        emit WinnerPicked(winner);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayersLength() external view returns (uint256) {
        return s_players.length;
    }

    function getPlayerByIndex(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
