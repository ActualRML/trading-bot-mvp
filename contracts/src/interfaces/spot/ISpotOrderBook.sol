// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface ISpotOrderBook {
    struct Order {
        uint256 id;
        address user;
        address base;  // base token
        address quote; // quote token
        uint256 price; // price in quote per base, scaled by PRICE_PRECISION
        uint256 amount; // amount of base token
        bool isBuy;
        bool active;
    }

    function getOrder(uint256 orderId) external view returns (Order memory);
    function reduceOrderAmount(uint256 orderId, uint256 filledAmount) external;
    function cancelOrder(uint256 orderId) external;
}