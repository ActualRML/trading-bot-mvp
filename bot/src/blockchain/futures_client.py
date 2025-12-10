from web3 import Web3
import json

# Load ABI
with open("./abis/FuturesExchange.json") as f:
    EXCHANGE_ABI = json.load(f)
with open("./abis/FuturesOrderBook.json") as f:
    ORDERBOOK_ABI = json.load(f)
with open("./abis/FuturesVault.json") as f:
    VAULT_ABI = json.load(f)

class FuturesClient:
    def __init__(self, web3: Web3, exchange_address, orderbook_address, vault_address, wallet_address, private_key):
        self.w3 = web3
        self.wallet = wallet_address
        self.pk = private_key
        self.exchange = web3.eth.contract(address=exchange_address, abi=EXCHANGE_ABI)
        self.orderbook = web3.eth.contract(address=orderbook_address, abi=ORDERBOOK_ABI)
        self.vault = web3.eth.contract(address=vault_address, abi=VAULT_ABI)

    # Deposit collateral ke vault
    def deposit_collateral(self, token, amount):
        tx = self.vault.functions.deposit(self.wallet, token, amount).buildTransaction({
            "from": self.wallet,
            "nonce": self.w3.eth.get_transaction_count(self.wallet)
        })
        signed = self.w3.eth.account.sign_transaction(tx, self.pk)
        return self.w3.eth.send_raw_transaction(signed.rawTransaction)

    # Open posisi long/short
    def open_position(self, asset, size, is_long, collateral_token, collateral_amount):
        tx = self.exchange.functions.openPosition(
            asset, size, is_long, collateral_token, collateral_amount
        ).buildTransaction({
            "from": self.wallet,
            "nonce": self.w3.eth.get_transaction_count(self.wallet)
        })
        signed = self.w3.eth.account.sign_transaction(tx, self.pk)
        return self.w3.eth.send_raw_transaction(signed.rawTransaction)

    # Close posisi
    def close_position(self, position_id, collateral_token, collateral_amount):
        tx = self.exchange.functions.closePosition(position_id, collateral_token, collateral_amount).buildTransaction({
            "from": self.wallet,
            "nonce": self.w3.eth.get_transaction_count(self.wallet)
        })
        signed = self.w3.eth.account.sign_transaction(tx, self.pk)
        return self.w3.eth.send_raw_transaction(signed.rawTransaction)

    # Ambil detail posisi
    def get_position(self, position_id):
        return self.exchange.functions.getPosition(position_id).call()

    # Ambil balance token di vault
    def get_balance(self, token):
        return self.vault.functions.freeBalanceOf(self.wallet, token).call()

    # ===== Tambahan: dummy get_price untuk testing =====
    def get_price(self, asset):
        # Bisa ganti ke oracle atau orderbook sebenarnya nanti
        # Contoh: return dummy harga 2000 USDT
        return 2000
