// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { PythOracleAdapter } from "../src/oracle/PythOracleAdapter.sol";
import { ChainlinkOracleAdapter } from "../src/oracle/ChainlinkOracleAdapter.sol";

contract OracleTest is Test {
    PythOracleAdapter pythAdapter;
    ChainlinkOracleAdapter chainlinkAdapter;

    address mockPyth = address(0x123);
    address mockChainlink = address(0x456);

    function setUp() public {
        pythAdapter = new PythOracleAdapter(mockPyth);
        chainlinkAdapter = new ChainlinkOracleAdapter(mockChainlink);
    }

    function testPythAdapterDeployed() public view {
        assert(address(pythAdapter) != address(0));
    }

    function testChainlinkAdapterDeployed() public view {
        assert(address(chainlinkAdapter) != address(0));
    }

    function testPythGetPriceRevertsOnMock() public {
        // Karena address 0x123 bukan contract, call akan revert.
        vm.expectRevert();
        pythAdapter.getPrice(bytes32(0));
    }

    function testChainlinkGetPriceRevertsOnMock() public {
        // Karena aggregator dummy, pasti revert.
        vm.expectRevert();
        chainlinkAdapter.getPrice();
    }
}
