// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { MockToken } from "../src/tokens/MockToken.sol";

contract MockTokenTest is Test {
    MockToken btc;
    address user = address(0x123);

    function setUp() public {
        //Deploy MockToken
        btc = new MockToken("Bitcoin", "BTC", 18);

        // Mint Token ke user
        btc.mint(user, 1000e18);
    }

    function testMint() public view {
        uint256 balance= btc.balanceOf(user);
        assertEq(balance, 1000e18, "User should have 1000 BTC");
    }

    function testTransfer() public {
        address receiver = address(0x456);
        // Simulate user transfering tokens
        vm.prank(user); //Transaksi seolah olah dari user
        require(btc.transfer(receiver, 100e18), "transfer failed");


        // Cek Balance 
        assertEq(btc.balanceOf(receiver), 100e18, "Receiver should get 100 BTC");
        assertEq(btc.balanceOf(user), 900e18, "User should have 900 BTC left");
    }

    function testDecimals() public view {
        assertEq(btc.decimals(), 18, "Decimals should be 18");
    }

}