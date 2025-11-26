// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library Utils {
    uint256 public constant DEFAULT_FEE_BPS = 8; // 0.08%

    /// @notice Hitung fee dari profit user dengan default 0.08% jika feeRate = 0
    /// @param profit Profit user dari posisi atau trade
    /// @param feeRate Fee rate dalam basis points (misal 200 = 2%). Jika 0, pakai default 0.08%.
    /// @return fee Fee yang dipotong untuk owner
    /// @return netProfit Sisa profit yang diterima user
    function calculateProfitFee(
        uint256 profit,
        uint256 feeRate
    ) internal pure returns (uint256 fee, uint256 netProfit) {
        if (profit == 0) {
            return (0, 0);
        }
        if (feeRate == 0) {
            feeRate = DEFAULT_FEE_BPS;
        }
        fee = (profit * feeRate) / 10000; // feeRate dalam basis points
        netProfit = profit - fee;
    }
}