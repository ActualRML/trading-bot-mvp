// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import { IPyth } from "@pythnetwork/IPyth.sol";
import { PythStructs } from "@pythnetwork/PythStructs.sol";
import { IOracleAdapter } from "../interfaces/IOracleAdapter.sol";


/// @notice Lightweight adapter to read price data from Pyth on-chain contract.
/// @dev This adapter uses `getPriceUnsafe` to read the last available price. Caller must ensure price freshness if needed.
contract PythOracleAdapter is IOracleAdapter {
    IPyth public immutable PYTH;


/// @param _pyth address of deployed Pyth contract on target chain
    constructor(address _pyth) {
        require(_pyth != address(0), "PythOracleAdapter: zero address");
        PYTH = IPyth(_pyth);
    }


/// @notice Read price tuple from Pyth for `priceId`.
/// @dev Returns (price, conf, expo). `price` and `conf` are taken from PythStructs.Price. `expo` is returned as uint64 for compatibility with interface.
    function getPrice(bytes32 priceId) external view override returns (int64 price, uint64 conf, uint64 expo) {
        PythStructs.Price memory p = PYTH.getPriceUnsafe(priceId);
            price = int64(p.price);
            conf = uint64(p.conf);
        // NOTE: Pyth's expo is signed (can be negative). We cast to uint64 here because interface expects uint64.
        // If you need signed expo keep it as int32/int64 instead.
        expo = uint64(uint32(p.expo));
    }
}