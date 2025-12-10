from utils.logger import log

class SpotStrategy:
    def __init__(self, client, user_address):
        self.client = client
        self.user_address = user_address

    def run(self, base, quote, amount):
        # contoh: check saldo
        balance = self.client.get_balance(base, self.user_address)
        log(f"Balance {base}: {balance}")

        # contoh: buat order beli
        price = "10000"  # mock price
        order_id = self.client.create_order(base, quote, price, amount, True)
        log(f"Created BUY order {order_id} for {amount} {base} at {price} {quote}")
