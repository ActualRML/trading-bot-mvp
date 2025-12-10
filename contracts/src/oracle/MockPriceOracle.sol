// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IPriceOracle } from "../interfaces/oracle/IPriceOracle.sol";

/// @notice Mock oracle untuk testing FuturesExchange
contract MockPriceOracle is IPriceOracle {
    mapping(bytes32 => uint256) public prices;

    /// @notice Set harga untuk asset tertentu
    function setPrice(bytes32 asset, uint256 price) external {
        prices[asset] = price;
    }

    /// @notice Mengembalikan harga asset
    function getPrice(bytes32 asset) external view override returns (uint256) {
        uint256 price = prices[asset];
        require(price > 0, "Price not set");
        return price;
    }
}
