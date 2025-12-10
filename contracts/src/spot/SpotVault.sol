// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AccessManaged } from "../libraries/AccessManaged.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { ISpotVault } from "../interfaces/spot/ISpotVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SpotVault
/// @notice Vault untuk Spot trading, menyimpan saldo user secara internal.
///         Deposit/withdraw user sekarang bener-bener memindahkan ERC20.
contract SpotVault is AccessManaged, ISpotVault {
    /// @notice token => user => balance (internal ledger)
    mapping(address => mapping(address => uint256)) public balances;

    /// @notice Exchange contract yang boleh melakukan transfer internal
    address public exchange;

    /// @notice Modifier untuk membatasi hanya exchange yang bisa panggil
    modifier onlyExchange() {
        _onlyExchange();
        _;
    }

    /// @dev Cek caller adalah exchange
    function _onlyExchange() internal view {
        if (msg.sender != exchange) revert Errors.Unauthorized(msg.sender);
    }

    constructor(address _owner) {
      if (_owner == address(0)) revert Errors.InvalidAddress();
      owner = _owner;
    }

    /// @notice Set address exchange yang boleh panggil internal transfer
    function setExchange(address _exchange) external onlyOwner {
        if (_exchange == address(0)) revert Errors.InvalidAddress();
        exchange = _exchange;
    }

    // ======================================
    // Deposit & Withdraw (USER FLOW)
    // ======================================

    /// @notice Deposit oleh caller sendiri (user-sign).
    /// @dev User harus approve token ke vault lebih dulu.
    function deposit(address token, uint256 amount) external {
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        // Pindahkan token dari user ke vault
        bool ok = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!ok) revert Errors.TransferFailed();

        // Update ledger internal
        balances[token][msg.sender] += amount;
        emit Events.Deposit(msg.sender, token, amount);
    }

    /// @notice Withdraw oleh caller sendiri (user-sign).
    /// @dev Vault mengirimkan kembali token ke user.
    function withdraw(address token, uint256 amount) external {
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        uint256 bal = balances[token][msg.sender];
        if (bal < amount) revert Errors.InsufficientBalance(bal, amount);

        balances[token][msg.sender] = bal - amount;

        bool ok = IERC20(token).transfer(msg.sender, amount);
        if (!ok) revert Errors.TransferFailed();

        emit Events.Withdraw(msg.sender, token, amount);
    }

    // ======================================
    // Admin / Dev hooks (optional)
    // ======================================

    /// @notice Deposit saldo untuk user tertentu (admin credit / faucet).
    /// @dev Tidak memindahkan token ERC20, hanya mengkredit ledger internal.
    function depositFor(
        address user,
        address token,
        uint256 amount
    ) external onlyOwner {
        if (user == address(0)) revert Errors.InvalidAddress();
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        balances[token][user] += amount;
        emit Events.Deposit(user, token, amount);
    }

    /// @notice Withdraw saldo untuk user tertentu (admin adjustment).
    /// @dev Tidak mengirim token ERC20, hanya mendebit ledger internal.
    function withdrawFor(
        address user,
        address token,
        uint256 amount
    ) external onlyOwner {
        if (user == address(0)) revert Errors.InvalidAddress();
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        uint256 bal = balances[token][user];
        if (bal < amount) revert Errors.InsufficientBalance(bal, amount);

        balances[token][user] = bal - amount;
        emit Events.Withdraw(user, token, amount);
    }

    // ======================================
    // Internal Transfer (dipanggil SpotExchange)
    // ======================================

    function transferBalance(
        address token,
        address from,
        address to,
        uint256 amount
    ) external override onlyExchange {
        if (token == address(0)) revert Errors.InvalidAddress();
        if (amount == 0) revert Errors.InvalidAmountForOrder();

        uint256 bal = balances[token][from];
        if (bal < amount) revert Errors.InsufficientBalance(bal, amount);

        balances[token][from] = bal - amount;
        balances[token][to] += amount;
        emit Events.VaultInternalTransfer(from, to, token, amount);
    }

    // ======================================
    // DEV / TESTNET ONLY
    // ======================================
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

            balances[token][user] += amount;
            emit Events.Deposit(user, token, amount);
        }
    }
}
