// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MultiSend} from "../src/MultiSend.sol";

contract MultiSendScript is Script {
    MultiSend public multiSend;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        multiSend = new MultiSend();

        vm.stopBroadcast();
    }
}
