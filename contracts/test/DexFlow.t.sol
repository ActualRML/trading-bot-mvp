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
        address tokenIn = address(0x1111);
        address tokenOut = address(0x2222);

        uint256 id = reg.createSession(
            tokenIn,
            tokenOut,
            1000,
            keccak256("meta")
        );
        assertEq(id, 1);

        (
            ,                      // id
            address user,
            address storedIn,
            address storedOut,
            uint256 cap,
            bytes32 meta,
            bool active
        ) = reg.sessions(id);

        assertEq(user, address(this));
        assertEq(storedIn, tokenIn);
        assertEq(storedOut, tokenOut);
        assertEq(cap, 1000);
        assertEq(meta, keccak256("meta"));
        assertTrue(active);
    }
}
