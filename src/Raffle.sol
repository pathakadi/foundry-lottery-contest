// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title A sample Raffle Contract
 * @author Aditya Pathak
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2{

    error Raffle__NotEnoughETHSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance,uint256 numPlayers,RaffleState raffleState);

    enum RaffleState { OPEN , CALCULATING }

    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastTimeStamp = 0;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable{
        if(msg.value < i_entranceFee) revert Raffle__NotEnoughETHSent();
        if(s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */

    function checkUpkeep() public view returns(bool){
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        bool upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return upkeepNeeded;
    }

    function performUpkeep() external{
        bool upkeepNeeded = checkUpkeep();
        if(!upkeepNeeded) revert Raffle__UpkeepNotNeeded(address(this).balance,s_players.length,s_raffleState);
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    // CEI : Checks , Effects and Interactions
    // Checks -> if and require statements with revert
    // Effects -> changes in our contract
    // Interactions -> interactions with other contracts
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override {
        // No Checks here
        // Effects
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        emit PickedWinner(winner);
        // Interactions
        (bool success , ) = winner.call{value : address(this).balance}("");
        if(!success) revert Raffle__TransferFailed();
    }

    // Getter Function

    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
    function getInterval() external view returns(uint256){
        return i_interval;
    }
    function getLastTimeStamp() external view returns(uint256){
        return s_lastTimeStamp;
    }
    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }
    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }
    function getPlayer(uint256 id) external view returns(address){
        return s_players[id];
    }
    function getTotalPlayers() external view returns(uint256){
        return s_players.length;
    }
}
/*
Layout of Contract:
    version
    imports
    errors
    interfaces, libraries, contracts
    Type declarations
    State variables
    Events
    Modifiers
    Functions

Layout of Functions:
    constructor
    receive function (if exists)
    fallback function (if exists)
    external
    public
    internal
    private
    view & pure functions
*/