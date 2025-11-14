// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


interface ISessionRegistry {
    function startSession() external;
    function endSession() external;
    function isActive(address user) external view returns (bool);
}