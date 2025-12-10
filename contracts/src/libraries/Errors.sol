// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library Errors {
    error Unauthorized(address caller);
    error InvalidAddress();

    error InsufficientBalance(uint256 available, uint256 required);
    error InvalidAmount();
    error InvalidAmountForOrder();
    error TransferFailed();

    error OrderAlreadyInactive(uint256 orderId);
    error InvalidOrder();
    error InvalidPrice();
    error OrderNotFound(uint256 orderId);
    error InvalidMatchAmount();
    error InsufficientOrderAmount(
        uint256 orderId,
        uint256 available,
        uint256 required
    );
    error OrderInactive(uint256 orderId);

    error BuyOrderPriceTooLow(uint256 buyPrice, uint256 sellPrice);
    error SellOrderPriceTooHigh(uint256 sellPrice, uint256 buyPrice);
    error IdenticalOrderSide();
    error TokenMismatch(address expected, address actual);
}
