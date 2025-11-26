// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { PythOracleAdapter } from "./PythOracleAdapter.sol";
import { ChainlinkOracleAdapter } from "./ChainlinkOracleAdapter.sol";

contract PriceOracleRouter {
    PythOracleAdapter public pyth;
    ChainlinkOracleAdapter public chainlink;

    constructor(address _pyth, address _chainlink) {
        pyth = PythOracleAdapter(_pyth);
        chainlink = ChainlinkOracleAdapter(_chainlink);
    }

    function getPrice(bytes32 priceId) external view returns (int256) {
        (int64 p, ) = pyth.getPrice(priceId);
        if (p > 0) return int256(p);
        return chainlink.getPrice();
    }
}
