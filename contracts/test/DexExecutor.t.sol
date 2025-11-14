// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DexExecutor} from "../src/DexExecutor.sol";

/// @notice Mock IOracleAdapter
contract MockOracle {
    int64 public price;
    function setPrice(int64 p) external { price = p; }
    function getPrice(bytes32) external view returns (int64, uint64, uint64) {
        return (price, uint64(1), uint64(0));
    }
}

/// @notice Mock SessionRegistry
contract MockSessionRegistry {
    mapping(address => bool) public active;
    function setActive(address user, bool a) external { active[user] = a; }
    function isActive(address user) external view returns (bool) { return active[user]; }
}

contract DexExecutorTest is Test {
    DexExecutor dex;
    MockOracle oracle;
    MockSessionRegistry registry;

    address owner = address(this);
    address alice = address(0xA1);

    event TradeExecuted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, int64 price);

    function setUp() public {
        oracle = new MockOracle();
        registry = new MockSessionRegistry();
        dex = new DexExecutor(address(oracle), address(registry));
    }

    function test_executeSwap_emits_event_with_price_when_session_active() public {
        // activate alice session
        registry.setActive(alice, true);
        // set oracle price
        oracle.setPrice(int64(12345));

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit TradeExecuted(alice, address(1), address(2), 100, int64(12345));

        vm.prank(alice);
        dex.executeSwap(address(1), address(2), 100);
    }

    function test_executeSwap_reverts_when_session_inactive() public {
        // ensure alice inactive
        registry.setActive(alice, false);
        vm.prank(alice);
        vm.expectRevert(bytes("DexExecutor: session inactive"));
        dex.executeSwap(address(1), address(2), 100);
    }

    function test_setOracle_onlyOwner() public {
        // non-owner cannot set
        vm.prank(address(0xB0));
        vm.expectRevert(bytes("AccessManaged: caller is not the owner"));
        dex.setOracle(address(0x123));

        // owner can set
        dex.setOracle(address(0x123));
        // no revert -> success; optionally verify storage via getter
        assertEq(address(dex.oracle()), address(0x123));
    }

    function test_setSessionRegistry_onlyOwner() public {
        vm.prank(address(0xB0));
        vm.expectRevert(bytes("AccessManaged: caller is not the owner"));
        dex.setSessionRegistry(address(0x456));

        dex.setSessionRegistry(address(0x456));
        assertEq(address(dex.sessionRegistry()), address(0x456));
    }
}
