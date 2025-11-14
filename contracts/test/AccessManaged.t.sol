// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { SessionRegistry } from "../src/SessionRegistry.sol";

contract SessionRegistryTest is Test {
    SessionRegistry sr;

    address alice = address(0xA1);
    address bob   = address(0xB0);

    function setUp() public {
        sr = new SessionRegistry();
    }

    function test_start_and_end_session_flow() public {
        // Alice starts session
        vm.prank(alice);
        sr.startSession();
        assertTrue(sr.isActive(alice));

        // Can't start again
        vm.prank(alice);
        vm.expectRevert(bytes("SessionRegistry: session already active"));
        sr.startSession();

        // Bob cannot end Alice's session
        vm.prank(bob);
        vm.expectRevert(bytes("SessionRegistry: no active session"));
        sr.endSession();

        // Alice ends session
        vm.prank(alice);
        sr.endSession();
        assertFalse(sr.isActive(alice));
    }

    function test_isActive_false_by_default() public view {
        assertFalse(sr.isActive(bob));
    }
}
