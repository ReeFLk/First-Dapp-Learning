// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {Pool} from "../src/Pool.sol";

contract DeployPool is Script{
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 duration = 4 weeks;
        uint256 goal = 10 ether;
        vm.startBroadcast(deployerPrivateKey);
        Pool pool = new Pool(duration, goal);
        vm.stopBroadcast();


    }
}
