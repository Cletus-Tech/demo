<?php

return [
    // USD value of each practice asset granted at signup and on demo reset.
    'starting_balances_usd' => [
        'BTC' => 5000,
        'ETH' => 2000,
        'USD' => 3000,
        'SOL' => 2000,
        'AAPL' => 1000,
    ],

    // Demo prices move only when the account requests a refresh and the interval elapsed.
    'price_refresh_interval_seconds' => 5,
    'price_volatility' => 0.006,
];
