// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IFuturesVault } from "../interfaces/futures/IFuturesVault.sol";
import { AccessManaged } from "../libraries/AccessManaged.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FuturesVault
/// @notice Vault untuk Futures trading, menyimpan saldo user internal dan lock collateral.
///         Withdraw user sekarang benar-benar mengirim ERC20 ke wallet user.
contract FuturesVault is AccessManaged, IFuturesVault {
    /// @notice total deposit per user/token (ledger internal)
    /// mapping(user => mapping(token => balance))
    mapping(address => mapping(address => uint256)) private _balances;

    /// @notice collateral yang dipakai posisi per user/token
    mapping(address => mapping(address => uint256)) private _locked;

    /// @notice hanya exchange yang boleh lock/unlock/transfer
    address public exchange;

    /// @notice modifier untuk hanya exchange
    modifier onlyExchange() {
        _onlyExchange();
        _;
    }

    function _onlyExchange() internal view {
        if (msg.sender != exchange) revert Errors.Unauthorized(msg.sender);
    }

    constructor(address _owner) {
        if (_owner == address(0)) revert Errors.InvalidAddress();
        owner = _owner;
    }

    /// @notice set address exchange
    function setExchange(address _exchange) external onlyOwner {
        if (_exchange == address(0)) revert Errors.InvalidAddress();
        exchange = _exchange;
    }

    // ==========================
    // DEPOSIT / WITHDRAW
    // ==========================

    /// @notice Deposit saldo untuk user tertentu (backend/admin credit).
    /// @dev TIDAK memindahkan token ERC20, hanya menambah ledger internal.
    function depositFor(
        address user,
        address token,
        uint256 amount
    ) external override onlyOwner {
        if (user == address(0)) revert Errors.InvalidAddress();
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        _balances[user][token] += amount;
        emit Events.Deposit(user, token, amount);
    }

    /// @notice Withdraw oleh caller sendiri (user).
    /// @dev Mengurangi ledger internal dan mengirim token ERC20 ke user.
    function withdraw(address token, uint256 amount) external override {
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        uint256 freeBal = freeBalanceOf(msg.sender, token);
        if (freeBal < amount) revert Errors.InsufficientBalance(freeBal, amount);

        _balances[msg.sender][token] -= amount;

        // Kirim token ERC20 dari vault ke user
        IERC20(token).transfer(msg.sender, amount);

        emit Events.Withdraw(msg.sender, token, amount);
    }

    /// @notice Withdraw saldo untuk user tertentu (backend/admin adjustment).
    /// @dev Hanya mengurangi ledger internal, tidak mengirim ERC20.
    function withdrawFor(
        address user,
        address token,
        uint256 amount
    ) external override onlyOwner {
        if (user == address(0)) revert Errors.InvalidAddress();
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        uint256 freeBal = freeBalanceOf(user, token);
        if (freeBal < amount) revert Errors.InsufficientBalance(freeBal, amount);

        _balances[user][token] -= amount;
        emit Events.Withdraw(user, token, amount);
    }

    // ==========================
    // COLLATERAL LOCKING
    // ==========================

    function lockCollateral(
        address user,
        address token,
        uint256 amount
    ) external override onlyExchange {
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        uint256 freeBal = freeBalanceOf(user, token);
        if (freeBal < amount) revert Errors.InsufficientBalance(freeBal, amount);

        _locked[user][token] += amount;
        emit Events.VaultLockCollateral(user, token, amount);
    }

    function unlockCollateral(
        address user,
        address token,
        uint256 amount
    ) external override onlyExchange {
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        uint256 lockedBal = _locked[user][token];
        if (lockedBal < amount) revert Errors.InsufficientBalance(lockedBal, amount);

        _locked[user][token] -= amount;
        emit Events.VaultUnlockCollateral(user, token, amount);
    }

    // ==========================
    // INTERNAL TRANSFER
    // ==========================

    function transferBalance(
        address token,
        address from,
        address to,
        uint256 amount
    ) external override onlyExchange {
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        uint256 freeBal = freeBalanceOf(from, token);
        if (freeBal < amount) revert Errors.InsufficientBalance(freeBal, amount);

        _balances[from][token] -= amount;
        _balances[to][token] += amount;

        emit Events.VaultInternalTransfer(from, to, token, amount);
    }

    // ==========================
    // BALANCE QUERIES
    // ==========================

    function balanceOf(
        address user,
        address token
    ) external view override returns (uint256) {
        return _balances[user][token];
    }

    function freeBalanceOf(
        address user,
        address token
    ) public view override returns (uint256) {
        return _balances[user][token] - _locked[user][token];
    }

    function lockedBalanceOf(
        address user,
        address token
    ) external view override returns (uint256) {
        return _locked[user][token];
    }

    // ==========================
    // DEV / TESTNET ONLY
    // ==========================

    /// @notice Faucet untuk testing (ledger internal saja).
    function faucet(
        address user,
        address[] calldata tokens,
        uint256 amount
    ) external onlyOwner {
        if (user == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) revert Errors.InvalidAddress();

            _balances[user][token] += amount;
            emit Events.Deposit(user, token, amount);
        }
    }
}
