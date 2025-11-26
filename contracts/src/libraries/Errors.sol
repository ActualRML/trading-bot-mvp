// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library Errors {

    // ============================
    // Access / Permission Errors
    // ============================
    error Unauthorized(address caller);
    error InvalidAddress();

    // ============================
    // Vault Errors
    // ============================
    error InsufficientBalance(uint256 available, uint256 required);
    error InvalidAmount();

    // ============================================================
    // Order Errors
    // ============================================================

    error OrderAlreadyInactive(uint256 orderId); // order sudah tidak aktif (cancelled/filled)
    error InvalidOrder(); // order tidak valid (tipe buy/sell atau token mismatch)
    error InvalidAmountForOrder(); // jumlah match = 0 atau tidak valid
    error InvalidPrice(); // harga match tidak sesuai aturan orderbook
    error OrderNotFound(uint256 orderId);
    error InvalidMatchAmount();
    error InsufficientOrderAmount(uint256 orderId, uint256 available, uint256 required);
    error OrderInactive(uint256 orderId);


    // ------------------------
    // EXCHANGE ERRORS
    // ------------------------
    error BuyOrderPriceTooLow(uint256 buyPrice, uint256 sellPrice);
    error SellOrderPriceTooHigh(uint256 sellPrice, uint256 buyPrice);
    error IdenticalOrderSide(); // buy matched with buy, sell matched with sell.
    error TokenMismatch(address expected, address actual);
}
