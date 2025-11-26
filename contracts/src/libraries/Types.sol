// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

struct Order {
    address user;
    bytes32 asset;
    uint256 amount;
    bool isBuy;
}

struct Position {
    address user;
    bytes32 asset;
    uint256 size;
    uint256 entryPrice;
    bool isLong;
}
