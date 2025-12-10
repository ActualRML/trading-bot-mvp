from blockchain.futures_client import FuturesClient

class FuturesStrategy:
    def __init__(self, client: FuturesClient, user_address: str):
        self.client = client
        self.user = user_address
        self.last_price = None
        self.open_position_id = None

    def should_open_long(self, price: float) -> bool:
        if self.last_price is None:
            return False
        return price < self.last_price * 0.99

    def should_close_long(self, price: float) -> bool:
        if self.last_price is None or self.open_position_id is None:
            return False
        return price > self.last_price * 1.01

    def run(self, asset: str, size: str, collateral_token: str, collateral_amount: str):
        price = float(self.client.get_price(asset))
        print(f"[FuturesStrategy] Current price {asset}/USDT: {price}")

        if self.should_open_long(price) and self.open_position_id is None:
            print("[FuturesStrategy] Opening long position...")
            position = self.client.open_position(asset, size, True, collateral_token, collateral_amount)
            self.open_position_id = position["positionId"]
            print(f"Position opened: {position}")

        elif self.should_close_long(price) and self.open_position_id is not None:
            print("[FuturesStrategy] Closing long position...")
            result = self.client.close_position(self.open_position_id, collateral_token, collateral_amount)
            print(f"Position closed: {result}")
            self.open_position_id = None

        self.last_price = price
