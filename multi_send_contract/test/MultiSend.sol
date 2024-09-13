// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultiSend} from "../src/MultiSend.sol";

contract MultiSendTest is Test {
    MultiSend public multiSend;

    address public acc_a = address(0x1);
    address public acc_b = address(0x2);
    address public acc_c = address(0x3);

    address[] public addresses;

    function setUp() public {
        multiSend = new MultiSend();

        vm.deal(acc_a, 10 ether);
        vm.prank(acc_a);
        (bool success_a, ) = address(multiSend).call{value: 5 ether}("");
        assertTrue(success_a, "Sending ETH failed");

        vm.deal(acc_b, 10 ether);
        vm.prank(acc_b);
        (bool success_b, ) = address(multiSend).call{value: 5 ether}("");
        assertTrue(success_b, "Sending ETH failed");

        vm.deal(acc_c, 10 ether);
        vm.prank(acc_c);
        (bool success_c, ) = address(multiSend).call{value: 5 ether}("");
        assertTrue(success_c, "Sending ETH failed");
    }

    function testSendETH() public {
        uint256 balance_a = multiSend.getBalance(acc_a);
        assertEq(balance_a, 5 ether, "acc_a's balance should be 5 ETH");

        uint256 balance_b = multiSend.getBalance(acc_b);
        assertEq(balance_b, 5 ether, "acc_b's balance should be 5 ETH");

        uint256 balance_c = multiSend.getBalance(acc_b);
        assertEq(balance_c, 5 ether, "acc_c's balance should be 5 ETH");
    }

    function testWithdrawETH() public {
        uint256 balanceBefore = multiSend.getBalance(acc_a);
        assertEq(balanceBefore, 5 ether, "acc_a's balance should be 5 ETH");

        vm.prank(acc_a);
        multiSend.withdraw(1 ether);

        uint256 balanceAfter = multiSend.getBalance(acc_a);
        assertEq(balanceAfter, 4 ether, "acc_a's balance should be 4 ETH after withdrawal");
    }


    function testCollect() public {
        multiSend.collect(acc_a, 50);

        uint256 contractBalance = multiSend.getBalance(address(multiSend));
        assertEq(contractBalance, 2.5 ether, "Contract's balance should be 2.5 ETH");
    }

    function testCollectAll() public {
        addresses.push(acc_a);
        addresses.push(acc_b);
        addresses.push(acc_c);

        multiSend.collectMany(addresses, 50);

        uint256 contractBalance = multiSend.getBalance(address(multiSend));
        assertEq(contractBalance, 7.5 ether, "Contract's balance should be 15 ETH");
    }

    function testDisperse() public {
        vm.deal(address(multiSend), 10 ether);

        multiSend.disperse(acc_a, 50);

        uint256 contractBalance = address(multiSend).balance;
        assertEq(contractBalance, 5 ether, "Contract's balance should be 5 ETH");
    }

    function testDisperseAll() public {
        addresses.push(acc_a);
        addresses.push(acc_b);

        vm.deal(address(multiSend), 10 ether);

        multiSend.disperseAll(addresses, 50);

        uint256 contractBalance = address(multiSend).balance;

        assertEq(contractBalance, 5 ether, "Contract's balance should be 5 ETH");
    }
}
