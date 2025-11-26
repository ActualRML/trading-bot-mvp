// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { FuturesVault } from "../src/futures/FuturesVault.sol";
import { FuturesOrderBook } from "../src/futures/FuturesOrderBook.sol";
import { FuturesExchange } from "../src/futures/FuturesExchange.sol";

contract DeployFutures is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy Vault
        FuturesVault vault = new FuturesVault();

        // Deploy OrderBook
        FuturesOrderBook orderBook = new FuturesOrderBook(msg.sender, address(vault));

        // Deploy Exchange
        address feeRecipient = 0xDEAD;
        uint256 feeBps = 10; 

        // ganti 'oracleAddress' dengan hasil deploy PriceOracleRouter
        address oracleAddress = 0x1111111111111111111111111111111111111111;

        FuturesExchange exchange = new FuturesExchange(
            msg.sender,
            address(vault),
            address(orderBook),
            oracleAddress,
            feeRecipient,
            feeBps
        );

        // Set exchange di Vault & OrderBook
        vault.setExchange(address(exchange));
        orderBook.setExchange(address(exchange));

        vm.stopBroadcast();
    }
}
