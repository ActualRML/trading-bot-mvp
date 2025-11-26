// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";

import { SpotVault } from "../src/spot/SpotVault.sol";
import { SpotOrderBook } from "../src/spot/SpotOrderBook.sol";
import { ISpotOrderBook } from "../src/interfaces/spot/ISpotOrderBook.sol";
import { SpotExchange } from "../src/spot/SpotExchange.sol";

/// @notice Minimal ERC20 mock tanpa import IERC20
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(_balances[msg.sender] >= amount, "insufficient");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "allowance");
        require(_balances[from] >= amount, "balance");
        _allowances[from][msg.sender] = allowed - amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }
}

/// @notice Mock oracle agar executeMatch tidak call ke address 0
contract MockOracle {
    int256 price;

    function setPrice(int256 _price) external {
        price = _price;
    }

    function getPrice(bytes32) external view returns (int256) {
        return price;
    }
}

contract SpotTest is Test {
    SpotVault vault;
    SpotOrderBook orderBook;
    SpotExchange exchange;
    MockOracle oracle;

    MockERC20 usdt;
    MockERC20 btc;

    address owner = address(this);
    address buyer = address(0xB0);
    address seller = address(0xC0);
    address feeRecipient = address(0xF0);

    function setUp() public {
        // Deploy mocks
        usdt = new MockERC20("Mock USDT", "mUSDT");
        btc  = new MockERC20("Mock BTC", "mBTC");
        oracle = new MockOracle();

        // Deploy Vault & OrderBook & Exchange
        vault = new SpotVault(address(this));
        orderBook = new SpotOrderBook();
        exchange = new SpotExchange(
            address(orderBook),
            address(vault),
            feeRecipient,
            100 // fee bps
        );

        // Set oracle ke exchange (mock)
        exchange.setOracle(address(oracle));
        // Wire contracts
        orderBook.setExchange(address(exchange));
        vault.setExchange(address(exchange));
        exchange.setMatcher(address(this));

        // Set oracle price supaya executeMatch aman
        oracle.setPrice(2_000e18);
    }

    function testDepositAndWithdraw() public {
        usdt.mint(buyer, 1_000e18);
        vm.prank(buyer);
        usdt.approve(address(vault), 1_000e18);
        vm.prank(buyer);
        vault.deposit(address(usdt), 1_000e18);

        assertEq(vault.balances(address(usdt), buyer), 1_000e18);

        vm.prank(buyer);
        vault.withdraw(address(usdt), 400e18);
        assertEq(vault.balances(address(usdt), buyer), 600e18);
    }

    function testCreateAndCancelOrder() public {
        vm.prank(buyer);
        uint256 buyId = orderBook.createOrder(address(btc), address(usdt), 2000e18, 1e18, true);

        vm.prank(seller);
        uint256 sellId = orderBook.createOrder(address(btc), address(usdt), 1900e18, 1e18, false);
        require(sellId > 0, "order creation failed");


        ISpotOrderBook.Order memory buyOrder = orderBook.getOrder(buyId);
        assertEq(buyOrder.user, buyer);
        assertEq(buyOrder.base, address(btc));
        assertEq(buyOrder.quote, address(usdt));
        assertEq(buyOrder.amount, 1e18);
        assertTrue(buyOrder.isBuy);

        vm.prank(buyer);
        orderBook.cancelOrder(buyId);

        ISpotOrderBook.Order memory buyAfter = orderBook.getOrder(buyId);
        assertTrue(!buyAfter.active);
        assertEq(buyAfter.amount, 0);
    }

    function testExecuteMatchFlowWithFee() public {
        btc.mint(seller, 2e18);
        usdt.mint(buyer, 2_500_000e18);

        vm.prank(seller);
        btc.approve(address(vault), 2e18);
        vm.prank(seller);
        vault.deposit(address(btc), 1e18);

        uint256 matchPrice = 1950e18;
        uint256 matchAmount = 1e18;
        uint256 quoteAmount = (matchAmount * matchPrice) / exchange.PRICE_PRECISION();
        uint256 fee = (quoteAmount * 100) / 10000; 
        uint256 depositQuote = quoteAmount + fee;

        vm.prank(buyer);
        usdt.approve(address(vault), depositQuote);
        vm.prank(buyer);
        vault.deposit(address(usdt), depositQuote);

        vm.prank(seller);
        uint256 sellId = orderBook.createOrder(address(btc), address(usdt), matchPrice, matchAmount, false);

        vm.prank(buyer);
        uint256 buyId = orderBook.createOrder(address(btc), address(usdt), 2000e18, matchAmount, true);

        exchange.executeMatch(buyId, sellId, matchAmount, matchPrice);

        assertEq(vault.balances(address(btc), buyer), matchAmount);
        assertEq(vault.balances(address(usdt), feeRecipient), fee);
        assertEq(vault.balances(address(usdt), seller), quoteAmount - fee);

        ISpotOrderBook.Order memory buyAfter = orderBook.getOrder(buyId);
        ISpotOrderBook.Order memory sellAfter = orderBook.getOrder(sellId);

        assertTrue(!sellAfter.active);
        assertTrue(!buyAfter.active);
        assertEq(buyAfter.amount, 0);
        assertEq(sellAfter.amount, 0);
    }

    function testExecuteMatch_RevertIfInvalidPriceOrAmount() public {
        vm.prank(seller);
        uint256 sellId = orderBook.createOrder(address(btc), address(usdt), 1900e18, 2e18, false);

        vm.prank(buyer);
        uint256 buyId = orderBook.createOrder(address(btc), address(usdt), 1800e18, 2e18, true);

        vm.expectRevert();
        exchange.executeMatch(buyId, sellId, 1e18, 1700e18);

        vm.expectRevert();
        exchange.executeMatch(buyId, sellId, 0, 1850e18);
    }
}
