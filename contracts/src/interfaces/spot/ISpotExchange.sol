// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface ISpotExchange {
    /// @notice Execute a trade between buy and sell orders
    function executeMatch(
        uint256 buyOrderId,
        uint256 sellOrderId,
        uint256 matchAmount,
        uint256 matchPrice
    ) external;

    /// @notice Admin helper: set vault address
    function setVault(address _vault) external;

    /// @notice Admin helper: set orderbook address
    function setOrderBook(address _orderBook) external;

    /// @notice Admin helper: set matcher address
    function setMatcher(address _matcher) external;

    /// @notice Admin helper: set fee BPS
    function setFeeBps(uint256 _feeBps) external;

    /// @notice Admin helper: set fee recipient
    function setFeeRecipient(address _recipient) external;

    /// @notice Admin helper: set oracle
    function setOracle(address _oracle) external;

    /// @notice Admin helper: set token price ID
    function setTokenPriceId(address token, bytes32 priceId) external;
}
