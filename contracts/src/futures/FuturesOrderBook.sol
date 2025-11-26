// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AccessManaged } from "../libraries/AccessManaged.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";
import { Position } from "../libraries/Types.sol";
import { IFuturesVault } from "../interfaces/futures/IFuturesVault.sol";

contract FuturesOrderBook is AccessManaged {
    IFuturesVault public vault; // Vault reference (kept for view but OrderBook won't call vault)
    address public exchange;

    // positionId => Position
    mapping(bytes32 => Position) public positions;
    uint256 public nextPositionId = 1;

    modifier onlyExchange() {
        _onlyExchange();
        _;
    }

    function _onlyExchange() internal view {
        if (msg.sender != exchange) revert Errors.Unauthorized(msg.sender);
    }

    constructor(address _owner, address _vault) {
        if (_owner == address(0) || _vault == address(0)) revert Errors.InvalidAddress();
        owner = _owner;
        vault = IFuturesVault(_vault);
    }

    function setExchange(address _exchange) external onlyOwner {
        if (_exchange == address(0)) revert Errors.InvalidAddress();
        exchange = _exchange;
    }

    // =========================
    // Open Position
    // =========================
    function openPosition(
        address user,
        bytes32 asset,
        uint256 size,
        bool isLong,
        address ,
        uint256 collateralAmount
    ) external onlyExchange returns (bytes32) {
        if (size == 0 || collateralAmount == 0) revert Errors.InvalidAmountForOrder();

        // NOTE: OrderBook no longer touches Vault.
        // Collateral lock must be performed by Exchange before calling this.

        // Generate positionId
        // forge-lint: disable-next-line(asm-keccak256)
        bytes32 positionId = keccak256(abi.encodePacked(nextPositionId, block.timestamp, user));
        nextPositionId++;

        // Store position
        positions[positionId] = Position({
            user: user,
            asset: asset,
            size: size,
            entryPrice: 0, // nanti bisa update pakai oracle
            isLong: isLong
        });

        emit Events.PositionOpened(positionId, user, asset, size, isLong);
        return positionId;
    }

    // =========================
    // Close Position
    // =========================
    function closePosition(bytes32 positionId, address /* collateralToken */, uint256 /* collateralAmount */) external onlyExchange {
        Position memory pos = positions[positionId];
        if (pos.user == address(0)) revert Errors.InvalidAddress();

        // NOTE: OrderBook no longer calls Vault.unlockCollateral.
        // Exchange must call vault.unlockCollateral after calling this function.

        // Hapus posisi
        delete positions[positionId];

        emit Events.PositionClosed(positionId, pos.user, pos.asset, pos.size, pos.isLong);
    }

    // =========================
    // Query Position
    // =========================
    function getPosition(bytes32 positionId) external view returns (Position memory) {
        return positions[positionId];
    }

    // =========================
    // Admin / Exchange updates
    // =========================
    function setEntryPrice(bytes32 positionId, uint256 price) external onlyExchange {
        Position storage pos = positions[positionId];
        if (pos.user == address(0)) revert Errors.InvalidAddress();
        pos.entryPrice = price;
    }
}
