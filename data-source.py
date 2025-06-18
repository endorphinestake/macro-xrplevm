#!/usr/bin/env python3

import sys
import requests

API_URL = "https://band-api.endorphinestake.com/api/prices"
DECIMALS = 8


def fetch_prices() -> str:
    """
    Fetch prices from external API and return string like:
    "Gold:33390000000,Silver:3674800000,..."
    Prices scaled by 1e8, quoteAsset must be 'USD'.
    """
    response = requests.get(API_URL, timeout=10)
    response.raise_for_status()
    raw_data = response.json()

    pairs = []
    for item in raw_data:
        base = item.get("baseAsset")
        quote = item.get("quoteAsset")
        price = item.get("price")

        if base and quote == "USD" and isinstance(price, (float, int)):
            scaled_price = int(round(price * (10**DECIMALS)))
            pairs.append(f"{base}:{scaled_price}")

    return ",".join(pairs)


def main():
    return fetch_prices()


if __name__ == "__main__":
    try:
        print(main())
    except Exception as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)
