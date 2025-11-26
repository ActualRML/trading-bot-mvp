// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface ISpotVault {
    /// transfer token balance inside vault from one user to another
    function transferBalance(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}