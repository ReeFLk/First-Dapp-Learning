// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

/**
 * @title Pool
 * @author ReeFLk
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Pool is Ownable{
    error Pool__CollectIsFinished();
    error Pool__GoalAlreadyReached();
    error Pool__CollectNotFinished();
    error Pool__FailedToSendEther();
    error Pool__NoContribution();
    error Pool__NotEnoughFunds();

    uint256 public end;
    uint256 public goal;
    uint256 public totalCollected;

    mapping(address => uint256) public contributions;

    event Contribute(address indexed contributor, uint256 amount);

    constructor(uint256 _duration, uint256 _goal) Ownable(msg.sender){
        end = block.timestamp + _duration;
        goal = _goal;
    }
    // @notice Allows to contribute to the pool 
    function contribute() public payable{
        if(block.timestamp > end){
            revert Pool__CollectIsFinished();
        }
        if(msg.value == 0){
            revert Pool__NoContribution();
        }
        contributions[msg.sender] += msg.value;
        totalCollected += msg.value;

        emit Contribute(msg.sender, msg.value);
    }

    // @notice Allow the owner to withdraw the funds
    function withdraw() external onlyOwner {
        if(block.timestamp < end || totalCollected < goal){
            revert Pool__CollectNotFinished();
        }
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        if (!sent) {
            revert Pool__FailedToSendEther();
        }
    }

    // @notice Allows the user to get a refund if the goal is not reached
    function refund() external{
        if (block.timestamp < end){
            revert Pool__CollectNotFinished();
        }
        if(totalCollected >= goal){
            revert Pool__GoalAlreadyReached();
        }
        if(contributions[msg.sender] == 0){
            revert Pool__NotEnoughFunds();
        }
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        totalCollected -= amount;
        (bool sent,) = msg.sender.call{value: amount}("");
        if (!sent) {
            revert Pool__FailedToSendEther();
        }
    }
}