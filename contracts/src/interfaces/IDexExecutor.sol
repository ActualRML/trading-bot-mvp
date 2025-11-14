// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


interface IDexExecutor {
    function executeSwap(address tokenIn, address tokenOut, uint256 amountIn) external;
}