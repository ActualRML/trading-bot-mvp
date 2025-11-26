// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IFuturesOrderBook {
    struct Order {
        uint256 id;
        address user;
        address base;   
        address quote;  
        uint256 amount; 
        uint256 price;  
        bool isBuy;
        bool active;
    }

    // Create an order, returns orderId
    function createOrder(
        address base,
        address quote,
        uint256 price,
        uint256 amount,
        bool isBuy
    ) external returns (uint256);

    // Cancel an order
    function cancelOrder(uint256 orderId) external;

    // Get order by id
    function getOrder(uint256 orderId) external view returns (Order memory);

    // Reduce remaining amount of an order after matching
    function reduceOrderAmount(uint256 orderId, uint256 amount) external;
}
