// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script, console } from 'forge-std/Script.sol';
import { Cashier } from '../src/Cashier.sol';

contract CashierScript is Script {
    Cashier public cashier;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        cashier = new Cashier(msg.sender);

        console.log('Cashier:', address(cashier));

        vm.stopBroadcast();
    }
}
