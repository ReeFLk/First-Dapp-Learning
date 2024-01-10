// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.23;

import {Test,console} from "forge-std/Test.sol";
import {Pool} from "../src/Pool.sol";

contract PoolTest is Test{
    address owner = makeAddr("owner");
    address addr1 = makeAddr("addr1");
    address addr2 = makeAddr("addr2");
    address addr3 = makeAddr("addr3");

    uint256 duration = 4 weeks;
    uint256 goal = 10 ether;

    Pool pool ;

    function setUp() public {
        vm.prank(owner);
        pool = new Pool(duration, goal);
    }

    function testContractDeployedSuccessfully() public {
        address _owner = pool.owner();
        assertEq(owner, _owner);
        uint256 _end= pool.end();
        assertEq(block.timestamp + duration, _end);
        uint256 _goal = pool.goal();
        assertEq(goal, _goal);
    }

    /*Contribute*/

    function test_RevertWhen_EndIsReached() public {
        vm.warp(pool.end()+3600);
        bytes4 selector = bytes4(keccak256("Pool__CollectIsFinished()"));
        console.logBytes4(selector);
        vm.expectRevert(abi.encodeWithSelector(selector));
        vm.prank(addr1);
        vm.deal(addr1,1 ether);
        pool.contribute{value: 1 ether}();
    }
    function test_RevertWhen_DontPay() public {
        vm.expectRevert(Pool.Pool__NoContribution.selector);
        vm.prank(addr1);
        pool.contribute();
    }
    function test_ExpectEmit__SuccessfullyContribute(uint96 _amount) public {
        vm.assume(_amount > 0);
        vm.expectEmit(true, false, false, true);
        emit Pool.Contribute(address(addr1), _amount);

        vm.prank(addr1);
        vm.deal(addr1, _amount);    
        pool.contribute{value: _amount}();
    }
    function test_AddTheAddressToTheContributionMappingWhenContribute() public{
        vm.prank(addr1);
        vm.deal(addr1, 1 ether);
        pool.contribute{value: 1 ether}();
        assertEq(pool.contributions(addr1),1 ether);
    }

    /*Withdraw*/
    function test_RevertWhen_NotTheOwner() public {
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, addr1));
        vm.prank(addr1);
        pool.withdraw();
    }

    function test_RevertWhen_ThePoolIsNotFinished() public {
        vm.warp(pool.end()-3600);
        vm.expectRevert(Pool.Pool__CollectNotFinished.selector);
        vm.prank(owner);
        pool.withdraw();
    }
    function test_RevertWhen_TheGoalOfThePoolIsNotReached() public {
        vm.prank(owner);
        vm.deal(owner, 1 ether);
        pool.contribute{value: 1 ether}();
        vm.expectRevert(Pool.Pool__CollectNotFinished.selector);
        vm.prank(owner);
        pool.withdraw();
    }
    function test_RevertWhen_WithdrawFailed() public{
        pool = new Pool(duration, goal); //become the owner

        vm.prank(addr1);
        vm.deal(addr1, 6 ether);
        pool.contribute{value: 6 ether}();

        vm.prank(addr2);
        vm.deal(addr2, 5 ether);
        pool.contribute{value: 5 ether}();

        vm.warp(pool.end()+3600);
        vm.expectRevert(Pool.Pool__FailedToSendEther.selector);
        //dont vm because TestPool is the owner now of the contract Pool
        pool.withdraw();
    }

    function test_Withdraw() public {
        vm.prank(addr1);
        vm.deal(addr1, 6 ether);
        pool.contribute{value: 6 ether}();

        vm.prank(addr2);
        vm.deal(addr2, 5 ether);
        pool.contribute{value: 5 ether}();

        vm.warp(pool.end()+3600);
        vm.prank(owner);
        pool.withdraw();
    }
    /*Refund*/
    function test_RevertWhen_NotFinished() public {
        vm.prank(addr1);
        vm.expectRevert(Pool.Pool__CollectNotFinished.selector);
        pool.refund();
    }
    function test_RevertWhen_GoalReached() public {
        vm.prank(addr1);
        vm.deal(addr1, 10 ether);
        pool.contribute{value: 10 ether}();

        vm.warp(pool.end()+3600);
        vm.prank(addr1);
        vm.expectRevert(Pool.Pool__GoalAlreadyReached.selector);
        pool.refund();
    }
    function test_RevertWhen_DontContribute() public {
        vm.prank(addr1);
        vm.warp(pool.end()+3600);
        vm.expectRevert(Pool.Pool__NotEnoughFunds.selector);
        pool.refund();
    }
    function test_RevertWhen_RefundFailedToSendEther() public {
        vm.deal(address(this), 2 ether);
        pool.contribute{value: 2 ether}();

        vm.warp(pool.end()+3600);
        vm.expectRevert(Pool.Pool__FailedToSendEther.selector);
        pool.refund();
    }
    function test_Refund() public {
        vm.prank(addr1);
        vm.deal(addr1, 1 ether);
        pool.contribute{value: 1 ether}();

        vm.warp(pool.end()+3600);
        vm.prank(addr1);
        pool.refund();
    }
}