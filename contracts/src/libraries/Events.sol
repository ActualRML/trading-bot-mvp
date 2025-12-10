// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library Events {

    // ============================
    // Access / Ownership Events
    // ============================
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ============================
    // Vault Events
    // ============================
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    event Withdraw(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    event VaultInternalTransfer(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount
    );

    event VaultLockCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    event VaultUnlockCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    // ============================
    // OrderBook Events
    // ============================
    event SpotOrderCreated(
        uint256 indexed orderId,
        address indexed user,
        address token,
        uint256 amount,
        uint256 price,
        bool isBuy
    );

    event SpotOrderCancelled(
        uint256 indexed orderId,
        address indexed user
    );

    // ============================
    // Execution Events
    // ============================
    event SpotOrderMatched(
        uint256 indexed tradeId,
        uint256 buyOrderId,
        uint256 sellOrderId,
        uint256 amount,
        uint256 price
    );

    event SpotTradeExecuted(
        uint256 indexed tradeId,
        uint256 buyOrderId,
        uint256 sellOrderId,
        address base,
        uint256 amount,
        uint256 price,
        address buyer,
        address seller,
        uint256 fee
    );

    // ============================
    // Position Events
    // ============================
    event PositionOpened(
        bytes32 positionId,
        address indexed user,
        bytes32 asset,
        uint256 size,
        bool isLong
    );

    event PositionClosed(
        bytes32 positionId,
        address indexed user,
        bytes32 asset,
        uint256 size,
        bool isLong
    );
}
