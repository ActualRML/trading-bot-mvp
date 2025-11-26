// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { MockToken } from "../src/tokens/MockToken.sol";

contract DeployMocks is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy Mock Tokens
        MockToken btc  = new MockToken("Bitcoin", "BTC", 18);
        MockToken eth  = new MockToken("Ethereum", "ETH", 18);
        MockToken usdt = new MockToken("Tether", "USDT", 6);
        MockToken sol  = new MockToken("Solana", "SOL", 18);
        MockToken ada  = new MockToken("Cardano", "ADA", 18);

        console2.log("BTC deployed at:", address(btc));
        console2.log("ETH deployed at:", address(eth));
        console2.log("USDT deployed at:", address(usdt));
        console2.log("SOL deployed at:", address(sol));
        console2.log("ADA deployed at:", address(ada));

        vm.stopBroadcast();
    }
}
