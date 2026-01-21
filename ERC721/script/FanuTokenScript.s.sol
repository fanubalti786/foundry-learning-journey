// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {FanuToken} from "../src/FanuToken.sol";

contract FanuTokenScript is Script {
    FanuToken public fanuToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        fanuToken = new FanuToken(msg.sender);

        vm.stopBroadcast();
    }
}