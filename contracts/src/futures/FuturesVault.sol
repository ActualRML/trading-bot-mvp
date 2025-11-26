// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IFuturesVault } from "../interfaces/futures/IFuturesVault.sol";
import { AccessManaged } from "../libraries/AccessManaged.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";

contract FuturesVault is AccessManaged, IFuturesVault {
    // total deposit per user/token
    mapping(address => mapping(address => uint256)) private _balances;
    // collateral yang dipakai posisi per user/token
    mapping(address => mapping(address => uint256)) private _locked;

    // hanya exchange yang boleh lock/unlock/transfer
    address public exchange;

    modifier onlyExchange() {
        _onlyExchange();
        _;
    }
           
    function _onlyExchange() internal view {
        if (msg.sender != exchange) revert Errors.Unauthorized(msg.sender);
    }

    function setExchange(address _exchange) external onlyOwner {
        if (_exchange == address(0)) revert Errors.InvalidAddress();
        exchange = _exchange;
    }

    // =================== Deposit / Withdraw ===================
    function deposit(address user, address token, uint256 amount) external override {
        if (amount == 0) revert Errors.InvalidAmountForOrder();
        _balances[user][token] += amount;
        emit Events.Deposit(user, token, amount);
    }


    function withdraw(address user, address token, uint256 amount) external override {
        if (amount == 0) revert Errors.InvalidAmountForOrder();
        uint256 freeBal = freeBalanceOf(user, token);
        if (freeBal < amount) revert Errors.InsufficientBalance(freeBal, amount);
        _balances[user][token] -= amount;
        emit Events.Withdraw(user, token, amount);
    }

    // =================== Collateral Locking ===================
    function lockCollateral(address user, address token, uint256 amount) external override onlyExchange {
        uint256 freeBal = freeBalanceOf(user, token);
        if (freeBal < amount) revert Errors.InsufficientBalance(freeBal, amount);
        _locked[user][token] += amount;
    }

    function unlockCollateral(address user, address token, uint256 amount) external override onlyExchange {
        uint256 lockedBal = _locked[user][token];
        if (lockedBal < amount) revert Errors.InsufficientBalance(lockedBal, amount);
        _locked[user][token] -= amount;
    }

    // =================== Balance Queries ===================
    function balanceOf(address user, address token) external view override returns (uint256) {
        return _balances[user][token];
    }

    function freeBalanceOf(address user, address token) public view override returns (uint256) {
        return _balances[user][token] - _locked[user][token];
    }

    // =================== Internal Transfer ===================
    function transferBalance(address token, address from, address to, uint256 amount) external override onlyExchange {
        uint256 freeBal = freeBalanceOf(from, token);
        if (amount == 0) revert Errors.InvalidAmountForOrder();
        if (freeBal < amount) revert Errors.InsufficientBalance(freeBal, amount);

        _balances[from][token] -= amount;
        _balances[to][token] += amount;

        emit Events.VaultInternalTransfer(from, to, token, amount);
    }
}
