// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/SessionRegistry.sol";

contract DexFlowTest is Test {
    SessionRegistry reg;

    function setUp() public {
        reg = new SessionRegistry();
    }

    function testCreateSession() public {
        uint id = reg.createSession("ETH/USDC", 1000, keccak256("meta"));
        assertEq(id, 1);
        ( , address user, , , , bool active) = reg.sessions(id);
        assertTrue(active);
        assertEq(user, address(this));
    }
}
