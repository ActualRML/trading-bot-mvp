// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/SessionRegistry.sol";
import "../src/Escrow.sol";
import "../src/DexExecutor.sol";

contract Deploy is Script {
    function run() external {
        // ENV yang dibaca dari shell:
        //   RPC_URL, PRIVATE_KEY (via CLI)
        //   ROUTER  = alamat router Base Sepolia
        address router = vm.envAddress("ROUTER"); // contoh: 0x9Bb8cC8a91e66D8293A8CAd4eCA561cA572d52FE

        vm.startBroadcast();

        SessionRegistry reg = new SessionRegistry();
        Escrow esc = new Escrow();
        DexExecutor dex = new DexExecutor(router);

        vm.stopBroadcast();

        console2.log("SessionRegistry:", address(reg));
        console2.log("Escrow:", address(esc));
        console2.log("DexExecutor:", address(dex));
        console2.log("Router:", router);
    }
}
