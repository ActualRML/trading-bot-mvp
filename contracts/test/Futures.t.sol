// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/futures/FuturesVault.sol";
import "../src/futures/FuturesOrderBook.sol";
import "../src/futures/FuturesExchange.sol";
import "../src/tokens/MockToken.sol";
import "../src/interfaces/oracle/IPriceOracle.sol";

// Mock Oracle
contract MockPriceOracle is IPriceOracle {
    mapping(bytes32 => uint256) public prices;

    function setPrice(bytes32 asset, uint256 price) external {
        prices[asset] = price;
    }

    function getPrice(bytes32 asset) external view override returns (uint256) {
        uint256 price = prices[asset];
        require(price > 0, "Price not set");
        return price;
    }
}

contract FuturesTest is Test {
    FuturesVault vault;
    FuturesOrderBook orderBook;
    FuturesExchange exchange;
    MockToken usdt;
    MockPriceOracle mockOracle;

    address owner;
    address feeRecipient;
    address trader1;
    address trader2;
    uint256 feeBps;

    // asset constant (use keccak256 to match contracts)
    bytes32 constant BTC = keccak256("BTC");

    // initial deposit used in setUp (for clarity)
    uint256 constant INITIAL_DEPOSIT = 100_000e18;

    function setUp() public {
        // owner = test contract
        owner = address(this);

        feeRecipient = address(0xDEAD);
        trader1 = address(0x1234);
        trader2 = address(0x5678);

        // fee bps (0.1% = 10 bps)
        feeBps = 10;

        // Deploy Vault & OrderBook
        vault = new FuturesVault();
        orderBook = new FuturesOrderBook(owner, address(vault));

        // Deploy MockOracle and set a price for BTC
        mockOracle = new MockPriceOracle();
        mockOracle.setPrice(BTC, 50_000e18);

        // Deploy Exchange
        exchange = new FuturesExchange(
            owner,
            address(vault),
            address(orderBook),
            address(mockOracle),
            feeRecipient,
            feeBps
        );

        // wire contracts (must be called by owner)
        vault.setExchange(address(exchange));
        orderBook.setExchange(address(exchange));

        // Mint token to owner & traders
        usdt = new MockToken("USDT", "USDT", 18);
        usdt.mint(owner, 1_000_000e18);
        usdt.mint(trader1, INITIAL_DEPOSIT);
        usdt.mint(trader2, INITIAL_DEPOSIT);

        // Deposits by traders and owner
        vm.startPrank(trader1);
        usdt.approve(address(vault), type(uint256).max);
        vault.deposit(trader1, address(usdt), INITIAL_DEPOSIT);
        vm.stopPrank();

        vm.startPrank(trader2);
        usdt.approve(address(vault), type(uint256).max);
        vault.deposit(trader2, address(usdt), INITIAL_DEPOSIT);
        vm.stopPrank();

        vm.startPrank(owner);
        usdt.approve(address(vault), type(uint256).max);
        vault.deposit(owner, address(usdt), INITIAL_DEPOSIT);
        vm.stopPrank();
    }

    // =========================
    // Test: Open Position
    // =========================
    function testOpenPosition() public {
        uint256 collateral = 10_000e18;

        // trader1 opens position
        vm.prank(trader1);
        bytes32 posId = exchange.openPosition(
            BTC,
            1e18,
            true,
            address(usdt),
            collateral
        );

        // verify position owner & asset
        (address user, bytes32 asset,,, bool isLong) = exchange.getPosition(posId);
        assertEq(user, trader1);
        assertEq(asset, BTC);
        assertTrue(isLong);

        // After open:
        // - fee moved from free balance to feeRecipient (vault.transferBalance)
        // - collateralAfterFee locked in vault
        // So trader1 free balance = INITIAL_DEPOSIT - collateral
        uint256 freeBal = vault.freeBalanceOf(trader1, address(usdt));
        assertEq(freeBal, INITIAL_DEPOSIT - collateral);
    }

    // =========================
    // Test: Close Position
    // =========================
    function testClosePosition() public {
        uint256 collateral = 10_000e18;

        // compute fee & collateralAfterFee
        uint256 fee = (collateral * feeBps) / 10_000;
        uint256 collateralAfterFee = collateral - fee;

        // trader1 opens
        vm.prank(trader1);
        bytes32 posId = exchange.openPosition(
            BTC,
            1e18,
            true,
            address(usdt),
            collateral
        );

        // now close — note: pass collateralAfterFee (amount that was locked)
        vm.prank(trader1);
        exchange.closePosition(posId, address(usdt), collateralAfterFee);

        // after close, collateralAfterFee returned to free balance, but fee already taken,
        // so final free balance = INITIAL_DEPOSIT - fee
        uint256 freeBal = vault.freeBalanceOf(trader1, address(usdt));
        assertEq(freeBal, INITIAL_DEPOSIT - fee);
    }

    // =========================
    // Test: Fee deduction
    // =========================
    function testFeeDeduction() public {
        uint256 collateral = 100_000e18;
        uint256 expectedFee = (collateral * feeBps) / 10_000;

        // trader1 opens position with large collateral
        vm.prank(trader1);
        bytes32 posId = exchange.openPosition(
            BTC,
            10e18,
            true,
            address(usdt),
            collateral
        );

        (address user, bytes32 asset,,, bool isLong) = exchange.getPosition(posId);
        assertEq(user, trader1);
        assertEq(asset, BTC);
        assertTrue(isLong);

        // FeeRecipient balance should equal expectedFee
        uint256 feeBal = vault.balanceOf(feeRecipient, address(usdt));
        assertEq(feeBal, expectedFee);

        // Also ensure trader1's free balance reduced by collateral (locked) and fee taken
        uint256 freeBal = vault.freeBalanceOf(trader1, address(usdt));
        // free = INITIAL_DEPOSIT - collateral
        assertEq(freeBal, INITIAL_DEPOSIT - collateral);
    }
}
