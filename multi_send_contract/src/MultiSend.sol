// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";

contract MultiSend {
    event Deposit(address indexed _from, uint _value);
    event Withdraw(address indexed _from, uint _value);
    event Collect(address indexed _from, uint _value);
    event Disperse(address indexed _from, uint _value);

    mapping(address => uint256) public balances;

    receive() external payable {
        emit Deposit(msg.sender, msg.value);

        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        uint256 balance = balances[msg.sender];

        require(amount > 0, "Zero balance");
        require(amount <= balance, "Insufficient balance");

        balances[msg.sender] = balance - amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
        emit Withdraw(msg.sender, amount);
    }

    function collect(address addr, uint8 percent) public {
        uint256 balance = balances[addr];
        uint amount = balance / 100 * percent;

        require(amount > 0, "Zero balance");
        require(amount <= balance, "Insufficient balance");

        (bool success, ) = address(this).call{value: amount}("");
        require(success, "Transfer failed.");

        emit Collect(addr, amount);
    }

    function collectMany(address[] memory addresses, uint8 percent) public {
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 balance = balances[addresses[i]];

            if(balance > 0) {
                uint256 amount = balance / 100 * percent;

                (bool success, ) = address(this).call{value: amount}("");
                require(success, "Transfer failed.");
                emit Collect(addresses[i], amount);
            }
        }
    }

    function disperse(address addr, uint8 percent) public {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Insufficient balance");

        uint256 amount = contractBalance / 100 * percent;

        (bool success, ) = addr.call{value: amount}("");
        require(success, "Transfer failed.");

        emit Disperse(addr, amount);
    }

    function disperseAll(address[] memory addresses, uint8 percent) public {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Insufficient balance");

        uint256 piePieceAmount =  contractBalance / addresses.length / 100 * percent;

        for(uint8 i; i < addresses.length; i++) {
            (bool success, ) = addresses[i].call{value: piePieceAmount}("");
            require(success, "Transfer failed.");

            emit Disperse(addresses[i], piePieceAmount);
        }

    }

    function getBalance(address addr) public view returns (uint256) {
        return balances[addr];
    }
}


