// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AccessManaged } from "../libraries/AccessManaged.sol";
import { Events } from "../libraries/Events.sol";
import { Errors } from "../libraries/Errors.sol";
import { ISpotOrderBook } from "../interfaces/spot/ISpotOrderBook.sol";



contract SpotOrderBook is AccessManaged, ISpotOrderBook {

    uint256 public nextOrderId;
    mapping(uint256 => Order) public orders;
    mapping(address => uint256[]) private userOrders;

    address public exchange;

    modifier onlyExchange() {
        _onlyExchange();
        _;
    }

    function _onlyExchange() internal view {
        if (msg.sender != exchange) revert Errors.Unauthorized(msg.sender);
    }


    // ----------------------------
    // Admin: set exchange
    // ----------------------------
    function setExchange(address _exchange) external onlyOwner {
        if (_exchange == address(0)) revert Errors.InvalidAddress();
        exchange = _exchange;
    }

    // ----------------------------
    // CREATE ORDER
    // ----------------------------
    function createOrder(
        address base,
        address quote,
        uint256 price,
        uint256 amount,
        bool isBuy
    ) external returns (uint256 orderId) {
        if (amount == 0) revert Errors.InvalidAmountForOrder();
        if (price == 0) revert Errors.InvalidPrice();

        orderId = ++nextOrderId;

        orders[orderId] = Order({
            id: orderId,
            user: msg.sender,
            base: base,
            quote: quote,
            price: price,
            amount: amount,
            isBuy: isBuy,
            active: true
        });

        userOrders[msg.sender].push(orderId);

        emit Events.SpotOrderCreated(orderId, msg.sender, base, amount, price, isBuy);
    }

    // ----------------------------
    // CANCEL ORDER
    // ----------------------------
    function cancelOrder(uint256 orderId) external {
        Order storage o = orders[orderId];
        if (o.id == 0) revert Errors.OrderNotFound(orderId);
        if (o.user != msg.sender) revert Errors.Unauthorized(msg.sender);
        if (!o.active) revert Errors.OrderAlreadyInactive(orderId);

        o.active = false;
        o.amount = 0;

        emit Events.SpotOrderCancelled(orderId, msg.sender);
    }

    // ----------------------------
    // REDUCE ORDER AMOUNT (exchange only)
    // ----------------------------
    function reduceOrderAmount(uint256 orderId, uint256 filledAmount)
        external
        onlyExchange
    {
        Order storage o = orders[orderId];
        if (o.id == 0) revert Errors.OrderNotFound(orderId);
        if (!o.active) revert Errors.OrderAlreadyInactive(orderId);
        if (filledAmount == 0) revert Errors.InvalidMatchAmount();
        if (o.amount < filledAmount)
            revert Errors.InsufficientOrderAmount(orderId, o.amount, filledAmount);

        o.amount -= filledAmount;

        if (o.amount == 0) {
            o.active = false;
        }
    }

    // ----------------------------
    // GETTERS
    // ----------------------------
    function getUserOrders(address user) external view returns (uint256[] memory) {
        return userOrders[user];
    }

    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }
}
