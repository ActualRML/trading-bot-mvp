// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PythOracle
 * @notice Thin helper around Pyth price feeds for on-chain price checks.
 *         - Stores two price IDs (tokenIn/USD and tokenOut/USD)
 *         - Allows pushing fresh updates via updatePriceFeeds(bytes[])
 *         - Exposes normalized prices in 1e18 fixed-point
 *         - Computes tokenIn/tokenOut price ratio with decimals handling
 *
 * Usage pattern (from another contract):
 *   1) fee = pythOracle.getUpdateFee(updateData)
 *   2) pythOracle.pushPrices{value: fee}(updateData)
 *   3) (pin, pout) = pythOracle.getPricesNoOlderThan(maxAge)
 *   4) minOutOracle = amountIn * pin / pout * 10^(decOut - decIn)
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// ===== Pyth minimal interfaces =====
library PythStructs {
    struct Price { int64 price; uint64 conf; int32 expo; uint publishTime; }
}

interface IPyth {
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint);
    function updatePriceFeeds(bytes[] calldata updateData) external payable;
    function getPriceNoOlderThan(bytes32 id, uint age)
        external
        view
        returns (PythStructs.Price memory);
}

contract PythOracle is Ownable, ReentrancyGuard {
    IPyth public immutable pyth;

    // Price IDs from Pyth (token/USD feeds)
    bytes32 public priceIdTokenIn;
    bytes32 public priceIdTokenOut;

    // Default staleness guard
    uint32 public maxAgeSeconds = 60; // configurable

    event PriceIdsUpdated(bytes32 priceIdIn, bytes32 priceIdOut);
    event MaxAgeUpdated(uint32 maxAgeSeconds);

    constructor(address _pyth, bytes32 _priceIdIn, bytes32 _priceIdOut) Ownable(msg.sender) {
        require(_pyth != address(0), "pyth=0");
        pyth = IPyth(_pyth);
        priceIdTokenIn = _priceIdIn;
        priceIdTokenOut = _priceIdOut;
        emit PriceIdsUpdated(_priceIdIn, _priceIdOut);
    }

    // ========= Admin =========
    function setPriceIds(bytes32 _in, bytes32 _out) external onlyOwner {
        priceIdTokenIn = _in;
        priceIdTokenOut = _out;
        emit PriceIdsUpdated(_in, _out);
    }

    function setMaxAgeSeconds(uint32 s) external onlyOwner {
        require(s > 0 && s <= 24 hours, "bad age");
        maxAgeSeconds = s;
        emit MaxAgeUpdated(s);
    }

    // ========= Update =========
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint fee) {
        fee = pyth.getUpdateFee(updateData);
    }

    function pushPrices(bytes[] calldata updateData) external payable nonReentrant {
        if (updateData.length > 0) {
            uint fee = pyth.getUpdateFee(updateData);
            require(msg.value >= fee, "fee");
            pyth.updatePriceFeeds{value: fee}(updateData);
            // refund excess
            if (msg.value > fee) {
                (bool ok, ) = msg.sender.call{value: msg.value - fee}("");
                require(ok, "refund");
            }
        }
    }

    // ========= Reads =========
    struct NormalizedPrice { uint256 value1e18; uint publishTime; }

    /**
     * @notice Returns tokenIn/USD and tokenOut/USD as 1e18 each, not older than `maxAgeSeconds`.
     */
    function getPricesNoOlderThan(uint32 age)
        public
        view
        returns (NormalizedPrice memory pin, NormalizedPrice memory pout)
    {
        uint32 _age = age == 0 ? maxAgeSeconds : age;
        PythStructs.Price memory inP = pyth.getPriceNoOlderThan(priceIdTokenIn, _age);
        PythStructs.Price memory outP = pyth.getPriceNoOlderThan(priceIdTokenOut, _age);
        require(inP.price > 0 && outP.price > 0, "oracle");
        pin = NormalizedPrice({value1e18: _toFixed(uint256(int256(inP.price)), inP.expo), publishTime: inP.publishTime});
        pout = NormalizedPrice({value1e18: _toFixed(uint256(int256(outP.price)), outP.expo), publishTime: outP.publishTime});
    }

    /**
     * @notice Returns price ratio tokenIn/tokenOut in 1e18, adjusting for ERC20 decimals.
     *         ratio = (pin / pout) * 10^(decOut - decIn)
     */
    function getPriceRatio(
        address tokenIn,
        address tokenOut,
        uint32 age
    ) external view returns (uint256 ratio1e18) {
        (NormalizedPrice memory pin, NormalizedPrice memory pout) = getPricesNoOlderThan(age);
        uint8 decIn = IERC20Metadata(tokenIn).decimals();
        uint8 decOut = IERC20Metadata(tokenOut).decimals();
        ratio1e18 = _mulDiv(
            pin.value1e18,
            _pow10(decOut),
            pout.value1e18
        ) / (10 ** decIn);
    }

    /**
     * @notice Compute oracle-based minOut for given amountIn and tokens.
     *         minOut = amountIn * ratio1e18 / 1e18 * (10_000 - bps)/10_000
     */
    function minOutFromOracle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint16 slippageBps,
        uint32 age
    ) external view returns (uint256 minOut) {
        require(slippageBps <= 10_000, "bps");
        uint256 ratio = this.getPriceRatio(tokenIn, tokenOut, age);
        uint256 expected = _mulDiv(amountIn, ratio, 1e18);
        minOut = _mulDiv(expected, 10_000 - slippageBps, 10_000);
    }

    // ========= Math helpers =========
    function _pow10(uint8 n) internal pure returns (uint256 r) {
        r = 1; for (uint8 i; i < n; i++) r *= 10;
    }

    function _toFixed(uint256 price, int32 expo) internal pure returns (uint256) {
        // Convert Pyth price (price * 10^expo) to 1e18 unsigned
        if (expo >= 0) {
            return price * (10 ** uint32(uint32(expo))) * 1e18;
        } else {
            return _mulDiv(price, 1e18, 10 ** uint32(uint32(-expo)));
        }
    }

    function _mulDiv(uint256 a, uint256 b, uint256 d) internal pure returns (uint256) {
        return (a * b) / d;
    }

    receive() external payable {}
}
