// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


interface IOracleAdapter {
/// @notice Return price tuple for a given priceId.
/// @dev The concrete adapter chooses semantics of priceId. Adapt return types to adapter implementation.
    function getPrice(bytes32 priceId) external view returns (int64 price, uint64 conf, uint64 expo);
}