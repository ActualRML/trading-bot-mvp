// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IFuturesVault {
    function deposit(address user, address token, uint256 amount) external;
    function withdraw(address user, address token, uint256 amount) external;
    function balanceOf(address user, address token) external view returns (uint256);
    function freeBalanceOf(address user, address token) external view returns (uint256);
    function lockCollateral(address user, address token, uint256 amount) external;
    function unlockCollateral(address user, address token, uint256 amount) external;
    function transferBalance(address token, address from, address to, uint256 amount) external;
}
