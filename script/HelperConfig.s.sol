// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script{
    struct NetworkConfig {
        uint256 entranceFee; 
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }
    NetworkConfig public activeNetworkConfig;
    constructor(){
        if(block.chainid == 11155111) activeNetworkConfig = getSepoliaEthConfig();
        else activeNetworkConfig = getOrCreateAnvilEthConfig();
    }
    function getSepoliaEthConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee : 0.01 ether,
            interval : 30,
            vrfCoordinator : 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId : 0,
            callbackGasLimit : 500000,
            link : 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey : vm.envUint("PRIVATE_KEY")
        });
    }
    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.vrfCoordinator != address(0)) return activeNetworkConfig;
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;
        vm.startBroadcast();
        LinkToken link = new LinkToken();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock( baseFee , gasPriceLink );
        vm.stopBroadcast();
        return NetworkConfig({
            entranceFee : 0.01 ether,
            interval : 30,
            vrfCoordinator : address(vrfCoordinatorMock),
            gasLane : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId : 0,
            callbackGasLimit : 500000,
            link : address(link),
            deployerKey : vm.envUint("DEFAULT_ANVIL_KEY")
        });
    }
}