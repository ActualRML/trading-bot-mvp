// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ISpotOrderBook } from "../interfaces/spot/ISpotOrderBook.sol";
import { ISpotVault } from "../interfaces/spot/ISpotVault.sol";
import { AccessManaged } from "../libraries/AccessManaged.sol";
import { Events } from "../libraries/Events.sol";
import { Errors } from "../libraries/Errors.sol";
import { PriceOracleRouter } from "../oracle/PriceOracleRouter.sol";
import { Utils } from "../libraries/Utils.sol";

/// @notice SpotExchange dengan 2-token settlement, pair validation, price precision dan dynamic fee handling
contract SpotExchange is AccessManaged {
    uint256 private _status;
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }
    function _nonReentrantBefore() internal {
        require(_status == 0, "Reentrant");
        _status = 1;
    }
    function _nonReentrantAfter() internal {
        _status = 0;
    }

    uint256 public constant PRICE_PRECISION = 1e18;

    ISpotOrderBook public orderBook;
    ISpotVault public vault;
    PriceOracleRouter public oracle;
    mapping(address => bytes32) public tokenPriceId;

    uint256 public nextTradeId;
    address public matcher;

    // ======================
    // Fee
    // ======================
    uint256 public feeBps;          
    address public feeRecipient;

    modifier onlyMatcher() {
        _onlyMatcher();
        _;
    }
           
    function _onlyMatcher() internal view {
        if (msg.sender != matcher) revert Errors.Unauthorized(msg.sender);
    }

    constructor(address _orderBook, address _vault, address _feeRecipient, uint256 _feeBps) {
        if (_orderBook == address(0) || _vault == address(0)) revert Errors.InvalidAddress();
        orderBook = ISpotOrderBook(_orderBook);
        vault = ISpotVault(_vault);
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
        _status = 0;
    }

    // ======================
    // Admin
    // ======================
    function setMatcher(address _matcher) external onlyOwner {
        if (_matcher == address(0)) revert Errors.InvalidAddress();
        matcher = _matcher;
    }

    function setFeeBps(uint256 _feeBps) external onlyOwner {
        require(_feeBps <= 1000, "fee too high");
        feeBps = _feeBps;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        if (_recipient == address(0)) revert Errors.InvalidAddress();
        feeRecipient = _recipient;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = PriceOracleRouter(_oracle);
    }

    function setTokenPriceId(address token, bytes32 priceId) external onlyOwner {
        tokenPriceId[token] = priceId;
    }

    function setOrderBook(address _orderBook) external onlyOwner {
        if (_orderBook == address(0)) revert Errors.InvalidAddress();
        orderBook = ISpotOrderBook(_orderBook);
    }

    function setVault(address _vault) external onlyOwner {
        if (_vault == address(0)) revert Errors.InvalidAddress();
        vault = ISpotVault(_vault);
    }

    // ======================
    // Core: Execute trade
    // ======================
    function executeMatch(
        uint256 buyOrderId,
        uint256 sellOrderId,
        uint256 matchAmount,
        uint256 matchPrice
    ) external onlyMatcher nonReentrant {
        ISpotOrderBook.Order memory buy = orderBook.getOrder(buyOrderId);
        ISpotOrderBook.Order memory sell = orderBook.getOrder(sellOrderId);

        int256 oraclePrice = oracle.getPrice(tokenPriceId[buy.base]);
        require(oraclePrice > 0, "oracle price not available");
        // oraclePrice is guaranteed >= 0 by the oracle design (no negative prices)
        // casting int256 -> uint256 safe
        // forge-lint: disable-next-line(unsafe-typecast)
        require(matchPrice <= uint256(oraclePrice), "matchPrice > oraclePrice");

        if (!buy.active) revert Errors.OrderInactive(buyOrderId);
        if (!sell.active) revert Errors.OrderInactive(sellOrderId);
        if (!buy.isBuy || sell.isBuy) revert Errors.InvalidOrder();
        if (matchAmount == 0) revert Errors.InvalidAmountForOrder();
        if (matchPrice == 0) revert Errors.InvalidPrice();
        if (buy.amount < matchAmount) revert Errors.InsufficientBalance(buy.amount, matchAmount);
        if (sell.amount < matchAmount) revert Errors.InsufficientBalance(sell.amount, matchAmount);

        if (buy.base == address(0) || buy.quote == address(0)) revert Errors.InvalidAddress();
        if (sell.base == address(0) || sell.quote == address(0)) revert Errors.InvalidAddress();
        if (buy.base != sell.base || buy.quote != sell.quote) revert Errors.InvalidOrder();

        if (!(matchPrice <= buy.price && matchPrice >= sell.price)) revert Errors.InvalidPrice();

        uint256 quoteAmount = (matchAmount * matchPrice) / PRICE_PRECISION;
        if (quoteAmount == 0) revert Errors.InvalidAmountForOrder();

        // ======================
        // Settlement
        // ======================
        // 1) BASE token: seller -> buyer
        vault.transferBalance(buy.base, sell.user, buy.user, matchAmount);

        // 2) QUOTE token: buyer -> seller minus fee
        uint256 fee = 0;
        uint256 netQuoteToSeller = quoteAmount;

        if (feeBps > 0 && feeRecipient != address(0)) {
            (fee, netQuoteToSeller) = Utils.calculateProfitFee(quoteAmount, feeBps);
            if (fee > 0) {
                vault.transferBalance(buy.quote, buy.user, feeRecipient, fee);
            }
        }

        vault.transferBalance(buy.quote, buy.user, sell.user, netQuoteToSeller);

        orderBook.reduceOrderAmount(buyOrderId, matchAmount);
        orderBook.reduceOrderAmount(sellOrderId, matchAmount);

        uint256 tradeId = ++nextTradeId;
        emit Events.SpotOrderMatched(tradeId, buyOrderId, sellOrderId, matchAmount, matchPrice);
        emit Events.SpotTradeExecuted(tradeId, buyOrderId, sellOrderId, buy.base, matchAmount, matchPrice, buy.user, sell.user, fee);
    }
}
