// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFCoordinatorV2Mock} from "../test/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint64 subscriptionId;
        bytes32 gasLane;
        uint256 automationUpdateInterval;
        uint256 raffleEntranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2;
        address link;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;

    event HelperConfig__CreatedMockVRFCoordinator(address vrfCoordinator);

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getAnvilChainConfig();
        }
    }



    function getSepoliaEthConfig()
        public
        view
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: 0, 
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            automationUpdateInterval: 30, 
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000,
            vrfCoordinatorV2: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getAnvilChainConfig()
        public
        returns (NetworkConfig memory anvilNetworkConfig)
    {
        if (activeNetworkConfig.vrfCoordinatorV2 != address(0)) {
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );

        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        emit HelperConfig__CreatedMockVRFCoordinator(
            address(vrfCoordinatorV2Mock)
        );

        anvilNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            automationUpdateInterval: 30,
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000,
            vrfCoordinatorV2: address(vrfCoordinatorV2Mock),
            link: address(link),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
