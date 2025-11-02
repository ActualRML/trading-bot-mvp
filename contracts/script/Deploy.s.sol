// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "../src/SessionRegistry.sol";
import "../src/Escrow.sol";
import "../src/DexExecutor.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        new SessionRegistry();
        new Escrow();
        new DexExecutor(address(0)); // e.g., UniswapV2Router02
        vm.stopBroadcast();
    }
}
