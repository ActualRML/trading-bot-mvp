// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { FuturesVault } from "../src/futures/FuturesVault.sol";
import { FuturesOrderBook } from "../src/futures/FuturesOrderBook.sol";
import { FuturesExchange } from "../src/futures/FuturesExchange.sol";

contract DeployFutures is Script {
    function run() external {
        vm.startBroadcast();

        // Deployer
        address deployer = msg.sender;

        // Deploy Vault
        FuturesVault vault = new FuturesVault();

        // Deploy OrderBook
        FuturesOrderBook orderBook = new FuturesOrderBook(deployer, address(vault));

        // Fee settings
        address feeRecipient = deployer; // jangan 0xDEAD
        uint256 feeBps = 10; // 0.1%

        // Oracle Router yang bener
        address oracleAddress = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;

        // Deploy Exchange
        FuturesExchange exchange = new FuturesExchange(
            deployer,
            address(vault),
            address(orderBook),
            oracleAddress,
            feeRecipient,
            feeBps
        );

        // Set exchange
        vault.setExchange(address(exchange));
        orderBook.setExchange(address(exchange));

        vm.stopBroadcast();
    }
}
