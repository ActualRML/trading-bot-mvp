import os
import requests

BASE_URL = os.getenv("BE_URL", "http://localhost:3000")

class SpotClient:
    def __init__(self):
        self.base_url = BASE_URL

    # Vault
    def get_balance(self, token: str, user: str):
        resp = requests.get(f"{self.base_url}/spot/balance?token={token}&user={user}")
        return resp.json()

    def deposit(self, token: str, amount: str):
        resp = requests.post(f"{self.base_url}/spot/deposit", json={"token": token, "amount": amount})
        return resp.json()

    def withdraw(self, token: str, amount: str):
        resp = requests.post(f"{self.base_url}/spot/withdraw", json={"token": token, "amount": amount})
        return resp.json()

    # OrderBook
    def create_order(self, base: str, quote: str, price: str, amount: str, is_buy: bool):
        resp = requests.post(
            f"{self.base_url}/spot/order",
            json={"base": base, "quote": quote, "price": price, "amount": amount, "isBuy": is_buy}
        )
        return resp.json()

    def cancel_order(self, order_id: int):
        resp = requests.post(f"{self.base_url}/spot/cancel/{order_id}")
        return resp.json()

    def get_order(self, order_id: int):
        resp = requests.get(f"{self.base_url}/spot/order/{order_id}")
        return resp.json()
