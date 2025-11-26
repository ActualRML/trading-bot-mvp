// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IFuturesExchange {
    
    /// @notice User open posisi futures
    /// @param asset Asset yang diperdagangkan
    /// @param size Size posisi
    /// @param isLong Long atau short
    /// @param collateralToken Token yang dijadikan collateral
    /// @param collateralAmount Jumlah collateral
    /// @return positionId ID posisi baru

    // User actions
    function openPosition(
        bytes32 asset,
        uint256 size,
        bool isLong,
        address collateralToken,
        uint256 collateralAmount
    ) external returns (bytes32);

    /// @notice User close posisi futures
    /// @param positionId ID posisi
    /// @param collateralToken Token yang dipakai untuk collateral
    /// @param collateralAmount Jumlah collateral yang dikembalikan
    function closePosition(
        bytes32 positionId,
        address collateralToken,
        uint256 collateralAmount
    ) external;

    // Admin / Exchange setup
    function setVault(address vault) external;
    function setOrderBook(address orderBook) external;

    // Query
    function getPosition(bytes32 positionId) external view returns (address user, bytes32 asset, uint256 size, uint256 entryPrice, bool isLong);
}
