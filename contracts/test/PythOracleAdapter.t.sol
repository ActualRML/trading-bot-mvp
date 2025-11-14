// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { PythOracleAdapter } from "../src/adapters/PythOracleAdapter.sol";
import { PythStructs } from "@pythnetwork/PythStructs.sol";

/// @notice Minimal mock of Pyth IPyth with getPriceUnsafe
contract MockPyth {
    mapping(bytes32 => PythStructs.Price) internal store;

    function setPrice(bytes32 id, int64 price, uint64 conf, int32 expo) external {
        PythStructs.Price memory p;
        p.price = price;
        p.conf = conf;
        p.expo = expo;
        // leave other fields default
        store[id] = p;
    }

    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory) {
        return store[id];
    }
}

contract PythOracleAdapterTest is Test {
    MockPyth mock;
    PythOracleAdapter adapter;

    bytes32 constant PID = bytes32(uint256(0x1234));

    function setUp() public {
        mock = new MockPyth();
        adapter = new PythOracleAdapter(address(mock));
    }

    function test_getPrice_returns_values() public {
        mock.setPrice(PID, int64(2500), uint64(10), int32(-8));
        (int64 price, uint64 conf, uint64 expo) = adapter.getPrice(PID);
        assertEq(price, 2500);
        assertEq(conf, 10);
        assertEq(expo, uint64(uint32(int32(-8))));
    }

    function test_constructor_reverts_zero_address() public {
        vm.expectRevert(bytes("PythOracleAdapter: zero address"));
        new PythOracleAdapter(address(0));
    }
}
