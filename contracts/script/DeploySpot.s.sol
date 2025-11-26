// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { SpotExchange } from "../src/spot/SpotExchange.sol";
import { SpotOrderBook } from "../src/spot/SpotOrderBook.sol";
import { SpotVault } from "../src/spot/SpotVault.sol";

contract DeploySpot is Script {
    function run() external {
        vm.startBroadcast();

        // Wallet deployer (lebih aman daripada msg.sender)
        address deployer = tx.origin;

        // Deploy Vault
        SpotVault vault = new SpotVault(deployer);
        console2.log("SpotVault deployed at:", address(vault));

        // Deploy OrderBook
        SpotOrderBook orderBook = new SpotOrderBook();
        console2.log("SpotOrderBook deployed at:", address(orderBook));

        // Deploy Exchange (feeBps = 50 → 0.5%)
        SpotExchange exchange = new SpotExchange(
            address(orderBook),
            address(vault),
            deployer,
            50
        );
        console2.log("SpotExchange deployed at:", address(exchange));

        // Link exchange → orderbook
        orderBook.setExchange(address(exchange));
        console2.log("OrderBook linked to Exchange");

        vm.stopBroadcast();
    }
}
