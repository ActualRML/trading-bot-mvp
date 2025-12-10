import time
from dotenv import load_dotenv
import os
from web3 import Web3
from blockchain.futures_client import FuturesClient
from strategies.futures_strategy import FuturesStrategy

load_dotenv()

w3 = Web3(Web3.HTTPProvider(os.getenv("RPC_URL")))
wallet = os.getenv("PRIVATE_KEY")
pk = os.getenv("PRIVATE_KEY")

exchange_address = os.getenv("FUTURES_EXCHANGE")
orderbook_address = os.getenv("FUTURES_ORDER_BOOK")
vault_address = os.getenv("FUTURES_VAULT")

client = FuturesClient(w3, exchange_address, orderbook_address, vault_address, wallet, pk)
strategy = FuturesStrategy(client, wallet)

asset = w3.keccak(text="ETH-USDT")
size = 1 * 10**18
collateral_token = os.getenv("TOKEN_ETH")
collateral_amount = 1 * 10**18

while True:
    try:
        strategy.run(asset, size, collateral_token, collateral_amount)
        time.sleep(10)  # cek tiap 10 detik
    except Exception as e:
        print("Error:", e)
        time.sleep(5)
