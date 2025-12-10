// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { MockToken } from "../src/tokens/MockToken.sol";
import { PriceOracleRouter } from "../src/oracle/PriceOracleRouter.sol";
import { MockPriceOracle } from "../src/oracle/MockPriceOracle.sol";
import { SpotVault } from "../src/spot/SpotVault.sol";
import { SpotOrderBook } from "../src/spot/SpotOrderBook.sol";
import { SpotExchange } from "../src/spot/SpotExchange.sol";
import { FuturesVault } from "../src/futures/FuturesVault.sol";
import { FuturesOrderBook } from "../src/futures/FuturesOrderBook.sol";
import { FuturesExchange } from "../src/futures/FuturesExchange.sol";

contract DeployAll is Script {
    function run() external {
        vm.startBroadcast();

        // 🔥 1. Deploy MOCK TOKENS
        MockToken btc  = new MockToken("Bitcoin", "BTC", 18);
        MockToken eth  = new MockToken("Ethereum", "ETH", 18);
        MockToken usdt = new MockToken("Tether", "USDT", 6);
        MockToken sol  = new MockToken("Solana", "SOL", 18);
        MockToken ada  = new MockToken("Cardano", "ADA", 18);

        console2.log("# ========== MOCK TOKENS ==========");
        console2.log("TOKEN_BTC=",address(btc));
        console2.log("TOKEN_ETH=",address(eth));
        console2.log("TOKEN_USDT=",address(usdt));
        console2.log("TOKEN_SOL=",address(sol));
        console2.log("TOKEN_ADA=",address(ada));

        uint256 amt18 = 1_000e18;     // untuk token 18 decimals
        uint256 amt6  = 1_000_000e6; // untuk USDT (6 decimals)

        // mint ke wallet deployer (msg.sender)
        btc.mint(msg.sender, amt18);
        eth.mint(msg.sender, amt18);
        usdt.mint(msg.sender, amt6);
        sol.mint(msg.sender, amt18); 
        ada.mint(msg.sender, amt18); 


        // 🔥 2. Deploy MOCK ORACLE
        MockPriceOracle mockOracle = new MockPriceOracle();

        // Set initial prices
        mockOracle.setPrice(keccak256("BTC"), 50_000e8);
        mockOracle.setPrice(keccak256("ETH"), 2_500e8);
        mockOracle.setPrice(keccak256("USDT"), 1e8);
        mockOracle.setPrice(keccak256("SOL"), 100e8);
        mockOracle.setPrice(keccak256("ADA"), 5e7); // 0.5 USD

        // 🔥 2b. Deploy ORACLE ROUTER dengan mockOracle
        PriceOracleRouter oracle = new PriceOracleRouter(
            address(mockOracle), // slot Pyth
            address(0)           // slot Chainlink (kosong)
        );

        console2.log("PRICE_ORACLE_ROUTER=",address(oracle));
        console2.log("MOCK_ORACLE=",address(mockOracle));


        // 🔥 3. Deploy SPOT Components
        SpotVault spotVault = new SpotVault(msg.sender);
        SpotOrderBook spotOrderBook = new SpotOrderBook();

        SpotExchange spotExchange = new SpotExchange(
            address(spotOrderBook),
            address(spotVault),
            msg.sender,
            50
        );

        spotVault.setExchange(address(spotExchange));
        spotOrderBook.setExchange(address(spotExchange));

        console2.log("# ========== SPOT DEPLOY ==========");
        console2.log("SPOT_VAULT=",address(spotVault));
        console2.log("SPOT_ORDER_BOOK=",address(spotOrderBook));
        console2.log("SPOT_EXCHANGE=",address(spotExchange));

        // 🔥 4. Deploy FUTURES Components
        FuturesVault futuresVault = new FuturesVault(msg.sender);
        FuturesOrderBook futuresOrderBook = new FuturesOrderBook(msg.sender, address(futuresVault));

        FuturesExchange futuresExchange = new FuturesExchange(
            msg.sender,
            address(futuresVault),
            address(futuresOrderBook),
            address(oracle),
            msg.sender,
            10
        );

        // Set exchange di vault & orderbook
        futuresVault.setExchange(address(futuresExchange));
        futuresOrderBook.setExchange(address(futuresExchange));

        console2.log("# ========== FUTURES DEPLOY ==========");
        console2.log("FUTURES_VAULT=",address(futuresVault));
        console2.log("FUTURES_ORDER_BOOK=",address(futuresOrderBook));
        console2.log("FUTURES_EXCHANGE=",address(futuresExchange));

        console2.log("DEPLOYER=", msg.sender);

        console2.log("# ========== DEPLOYMENT COMPLETE ==========");

        vm.stopBroadcast();
    }
}
