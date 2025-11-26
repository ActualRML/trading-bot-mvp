// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AccessManaged } from "../libraries/AccessManaged.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { Position } from "../libraries/Types.sol";
import { IFuturesVault } from "../interfaces/futures/IFuturesVault.sol";
import { IFuturesExchange } from "../interfaces/futures/IFuturesExchange.sol";
import { IPriceOracle } from "../interfaces/oracle/IPriceOracle.sol";
import { FuturesOrderBook } from "./FuturesOrderBook.sol";
import { Utils } from "../libraries/Utils.sol";

contract FuturesExchange is AccessManaged, IFuturesExchange {
    IFuturesVault public vault;
    FuturesOrderBook public orderBook;
    IPriceOracle public oracle;

    uint256 public feeBps;
    address public feeRecipient;

    constructor(
        address _owner,
        address _vault,
        address _orderBook,
        address _oracle,
        address _feeRecipient,
        uint256 _feeBps
    ) {
        if (
            _owner == address(0) ||
            _vault == address(0) ||
            _orderBook == address(0) ||
            _oracle == address(0)
        ) revert Errors.InvalidAddress();

        // set owner from constructor arg (AccessManaged.owner)
        owner = _owner;

        vault = IFuturesVault(_vault);
        orderBook = FuturesOrderBook(_orderBook);
        oracle = IPriceOracle(_oracle);

        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
    }

    // =========================
    // Admin setup
    // =========================
    function setVault(address _vault) external onlyOwner {
        if (_vault == address(0)) revert Errors.InvalidAddress();
        vault = IFuturesVault(_vault);
    }

    function setOrderBook(address _orderBook) external onlyOwner {
        if (_orderBook == address(0)) revert Errors.InvalidAddress();
        orderBook = FuturesOrderBook(_orderBook);
    }

    function setOracle(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert Errors.InvalidAddress();
        oracle = IPriceOracle(_oracle);
    }

    function setFee(uint256 _feeBps, address _recipient) external onlyOwner {
        require(_feeBps <= 1000, "Fee too high"); // max 10%
        require(_recipient != address(0), "Invalid fee recipient");

        feeBps = _feeBps;
        feeRecipient = _recipient;
    }

    // =========================
    // User actions
    // =========================
    function openPosition(
        bytes32 asset,
        uint256 size,
        bool isLong,
        address collateralToken,
        uint256 collateralAmount
    ) external override returns (bytes32) {
        if (size == 0 || collateralAmount == 0) revert Errors.InvalidAmountForOrder();

        address user = msg.sender;

        // Hitung fee
        (uint256 fee, uint256 collateralAfterFee) = Utils.calculateProfitFee(collateralAmount, feeBps);

        // Transfer fee dari user ke feeRecipient via Vault internal ledger (Exchange must be authorized in Vault)
        if (fee > 0 && feeRecipient != address(0)) {
            vault.transferBalance(collateralToken, user, feeRecipient, fee);
        }

        // Lock collateral di Vault (Exchange harus memanggil ini — OrderBook tidak boleh)
        vault.lockCollateral(user, collateralToken, collateralAfterFee);

        // Open position di OrderBook (OrderBook hanya menyimpan posisi, tidak menyentuh Vault)
        bytes32 positionId = orderBook.openPosition(
            user,
            asset,
            size,
            isLong,
            collateralToken,
            collateralAfterFee
        );

        // Set entryPrice dari oracle
        uint256 price = oracle.getPrice(asset);
        orderBook.setEntryPrice(positionId, price);

        emit Events.PositionOpened(positionId, user, asset, size, isLong);
        return positionId;
    }

    function closePosition(
        bytes32 positionId,
        address collateralToken,
        uint256 collateralAmount
    ) external override {
        Position memory pos = orderBook.getPosition(positionId);
        if (pos.user == address(0)) revert Errors.InvalidAddress();
        if (pos.user != msg.sender) revert Errors.Unauthorized(msg.sender);

        // Safety check: collateralAmount harus tersedia di locked balance.
        uint256 totalBal = vault.balanceOf(msg.sender, collateralToken);
        uint256 freeBal = vault.freeBalanceOf(msg.sender, collateralToken);
        uint256 lockedBal = totalBal - freeBal;
        if (lockedBal < collateralAmount) revert Errors.InsufficientBalance(lockedBal, collateralAmount);

        uint256 price = oracle.getPrice(pos.asset);

        // PnL calculation with precision fix
        int256 pnl = calculatePnL(pos.size, pos.entryPrice, price, pos.isLong);

        uint256 fee = 0;
        uint256 netProfit = 0;

        // Fee jika profit (ambil dari pnl)
        if (pnl > 0 && feeRecipient != address(0)) {
            (fee, netProfit) = Utils.calculateProfitFee(uint256(pnl), feeBps);
            pnl -= int256(fee);

            // Transfer fee dari user (pnl) ke recipient via ledger
            // Note: pnl is profit (off-ledger), but we model fee by moving tokens from user balance to feeRecipient
            // Ensure user has enough free balance to pay fee if needed — here fee taken from user's vault free balance
            vault.transferBalance(collateralToken, msg.sender, feeRecipient, fee);
        } else {
            netProfit = pnl >= 0 ? uint256(pnl) : 0;
        }

        // Close position in orderbook (OrderBook will not touch Vault)
        orderBook.closePosition(positionId, collateralToken, collateralAmount);

        // Adjust collateral in Vault: unlock collateral + profit or unlock remaining after loss
        if (pnl >= 0) {
            // return collateral + profit
            vault.unlockCollateral(msg.sender, collateralToken, collateralAmount + netProfit);
        } else {
            // user had loss: unlock remaining collateral after loss
            uint256 loss = uint256(pnl * -1);
            uint256 toUnlock = collateralAmount > loss ? collateralAmount - loss : 0;
            vault.unlockCollateral(msg.sender, collateralToken, toUnlock);
        }

        emit Events.PositionClosed(positionId, msg.sender, pos.asset, pos.size, pos.isLong);
    }

    // =========================
    // Query
    // =========================
    function getPosition(bytes32 positionId)
        external
        view
        override
        returns (address user, bytes32 asset, uint256 size, uint256 entryPrice, bool isLong)
    {
        Position memory pos = orderBook.getPosition(positionId);
        return (pos.user, pos.asset, pos.size, pos.entryPrice, pos.isLong);
    }

    // ========= SAFE CAST HELPERS =========

    function _toInt(uint256 x) internal pure returns (int256) {
        require(x <= uint256(type(int256).max), "Overflow uint->int");
        // Safe because we already ensured x <= int256.max
        // forge-lint: disable-next-line(unsafe-typecast)
        return int256(x);
    }

    // =========================
    // PnL Calculation (SAFE)
    // =========================
    function calculatePnL(
        uint256 size,
        uint256 entryPrice,
        uint256 exitPrice,
        bool isLong
    ) internal pure returns (int256 pnl) {
        uint256 precision = 1e18;

        int256 ePrice = _toInt(entryPrice);
        int256 xPrice = _toInt(exitPrice);

        int256 rawPnl;
        if (isLong) {
            rawPnl = xPrice - ePrice;
        } else {
            rawPnl = ePrice - xPrice;
        }

        // Hitung dengan precision sebelum dibagi entryPrice
        pnl = (rawPnl * _toInt(size) * _toInt(precision)) / ePrice / _toInt(precision);
    }
}
