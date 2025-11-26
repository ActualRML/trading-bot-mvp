// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IPyth } from "@pyth/IPyth.sol";
import { PythStructs } from "@pyth/PythStructs.sol";

contract PythOracleAdapter {
    IPyth public pyth;

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    function getPrice(bytes32 priceId) external view returns (int64, uint64) {
        PythStructs.Price memory p = pyth.getPriceNoOlderThan(priceId, 30);
        return (p.price, p.conf);
    }
}
