// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { PriceOracleRouter } from "../src/oracle/PriceOracleRouter.sol";

contract DeployOracle is Script {
    function run() external {
        vm.startBroadcast();

        // NOTE:
        // Replace dengan address oracle beneran kalau nanti sudah deploy mock Pyth dan Chainlink adapter.
        address pythAddress = address(0);
        address chainlinkAddress = address(0);

        PriceOracleRouter oracle =
            new PriceOracleRouter(pythAddress, chainlinkAddress);

        console2.log("Oracle Router deployed at:", address(oracle));

        vm.stopBroadcast();
    }
}
