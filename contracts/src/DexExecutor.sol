// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import { AccessManaged } from "./utils/AccessManaged.sol";
import { IOracleAdapter } from "./interfaces/IOracleAdapter.sol";
import { ISessionRegistry } from "./interfaces/ISessionRegistry.sol";


contract DexExecutor is AccessManaged {
    IOracleAdapter public oracle;
    ISessionRegistry public sessionRegistry;

    event OracleUpdated(address indexed newOracle);
    event SessionRegistryUpdated(address indexed newRegistry);
    event TradeExecuted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, int64 price);


    constructor(address _oracle, address _sessionRegistry) {
        if (_oracle != address(0)) oracle = IOracleAdapter(_oracle);
        if (_sessionRegistry != address(0)) sessionRegistry = ISessionRegistry(_sessionRegistry);
    }


    function setOracle(address newOracle) external onlyOwner {
        oracle = IOracleAdapter(newOracle);
        emit OracleUpdated(newOracle);
    }


    function setSessionRegistry(address newRegistry) external onlyOwner {
        sessionRegistry = ISessionRegistry(newRegistry);
        emit SessionRegistryUpdated(newRegistry);
    }


/// @notice Simulate a swap. Does not move funds. Emits price at execution time.
/// @dev For MVP this function only reads oracle and emits an event. `msg.sender` is considered the user.
    function executeSwap(address tokenIn, address tokenOut, uint256 amountIn) external {
        require(amountIn > 0, "DexExecutor: zero amount");
        // optional: check session active if sessionRegistry is set
        if (address(sessionRegistry) != address(0)) {
        require(sessionRegistry.isActive(msg.sender), "DexExecutor: session inactive");
        }


        int64 price = 0;
        if (address(oracle) != address(0)) {
        // derive priceId for pair: this is a simple deterministic choice for MVP
        bytes32 priceId;
        assembly {
            mstore(0x00, tokenIn)
            mstore(0x20, tokenOut)
            priceId := keccak256(0x00, 0x40)
            }
        (int64 p, , ) = oracle.getPrice(priceId);
        price = p;
        }


        emit TradeExecuted(msg.sender, tokenIn, tokenOut, amountIn, price);
    }
}