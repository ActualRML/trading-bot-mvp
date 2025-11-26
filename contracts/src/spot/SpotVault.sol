// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AccessManaged } from "../libraries/AccessManaged.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { ISpotVault } from "../interfaces/spot/ISpotVault.sol";

/// @title SpotVault
/// @notice Vault untuk Spot trading, menyimpan saldo user secara internal (mock token)
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
    // Deposit & Withdraw
    // ======================================

    function deposit(address token, uint256 amount) external {
        if (amount == 0) revert Errors.InvalidAmountForOrder();
        if (token == address(0)) revert Errors.InvalidAddress();

        balances[token][msg.sender] += amount;
        emit Events.Deposit(msg.sender, token, amount);
    }


    function withdraw(address token, uint256 amount) external {
        if (amount == 0) revert Errors.InvalidAmountForOrder();
        uint256 bal = balances[token][msg.sender];
        if (bal < amount) revert Errors.InsufficientBalance(bal, amount);

        balances[token][msg.sender] -= amount;
        emit Events.Withdraw(msg.sender, token, amount);
    }

    // ======================================
    // Internal Transfer (dipanggil SpotExchange)
    // ======================================

    /// @notice Transfer saldo antar user, hanya Exchange yang boleh panggil
    function transferBalance(
        address token,
        address from,
        address to,
        uint256 amount
    ) external override onlyExchange {
        if (amount == 0) revert Errors.InvalidAmountForOrder();
        uint256 bal = balances[token][from];
        if (bal < amount) revert Errors.InsufficientBalance(bal, amount);

        balances[token][from] -= amount;
        balances[token][to] += amount;
        emit Events.VaultInternalTransfer(from, to, token, amount);
    }
}
