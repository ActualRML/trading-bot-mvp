// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IPriceOracle {
    function getPrice(bytes32 asset) external view returns (uint256);
}
