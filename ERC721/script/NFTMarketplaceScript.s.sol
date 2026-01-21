// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract NFTMarketplaceScript is Script {
    NFTMarketplace public nftMarketplace;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        nftMarketplace = new NFTMarketplace(msg.sender);

        vm.stopBroadcast();
    }
}