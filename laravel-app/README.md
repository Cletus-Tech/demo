# Laravel Brokerage Dashboard — integration package

A Laravel-native foundation for the brokerage dashboard shown in the supplied reference screenshots. The package preserves the original dark dashboard Blade interface and adds Laravel session authentication plus a database-backed demo brokerage API.

## Included
- Existing dashboard UI in `resources/views/dashboard.blade.php`.
- Laravel login, registration and logout controllers/views.
- Auth-protected dashboard route.
- Database migration for demo assets, wallets, transactions, positions, notifications and service enquiries.
- Eloquent models and a demo API controller for account state, demo deposits/withdrawals/buys/sells, opening/closing demo positions and service enquiries.
- Seed market assets (BTC, ETH, SOL, USD and EUR) created by the migration.

## Install into a fresh Laravel application
1. Create a Laravel application (Laravel 11/12 recommended).
2. Copy the contents of this `laravel-app` directory into the Laravel project root, merging folders. Do not overwrite existing host-project files blindly.
3. Install API authentication support if it is not already present: `php artisan install:api` (Sanctum).
4. Merge the supplied `routes/web.php` and `routes/api.php` route definitions into the host application's route files. Keep existing routes.
5. Confirm `App\\Models\\User` uses Laravel's standard authenticatable model and the standard `users` table migration. Registration uses `name`, `email` and `password`.
6. Configure `.env` database credentials, then run:
   ```bash
   php artisan key:generate
   php artisan migrate
   php artisan serve
   ```
7. Visit `/register`, create a test account, then open `/dashboard`.

## API endpoints
All endpoints are protected by `auth:sanctum` and intended for same-origin authenticated requests with Laravel Sanctum CSRF/session setup.

- `GET /api/broker/state` — profile, assets, wallets, open positions and recent transactions.
- `POST /api/broker/transactions` — demo deposit, withdrawal, buy or sell.
- `POST /api/broker/positions` — open a demo leveraged position.
- `POST /api/broker/positions/{id}/close` — close an owned open position.
- `GET /api/broker/services` and `POST /api/broker/services` — list/create service enquiries.

Transaction payload: `{ "type":"deposit", "symbol":"USD", "amount":1000 }`.
Position payload: `{ "symbol":"BTC", "side":"buy", "quantity":0.01, "leverage":2 }`.

## Current scope and limitations
This is a **Laravel integration package/foundation**, not yet a fully verified drop-in turnkey application. The Blade dashboard's existing inline JavaScript still contains the previous browser API contract and has not yet been fully switched over to the Laravel endpoints. Some dashboard interactions therefore still require the frontend adapter/integration pass.

The included demo API is intentionally limited: it does not provide live market feeds, real exchange execution, real-money deposits/withdrawals, custody, KYC/AML, payment processing, liquidation engines, or production financial controls. It is for local demonstration and integration testing only. Never use real funds or describe simulated prices/balances as live trading.

## Verification
No Laravel runtime test has been run in this environment because no PHP/Laravel runtime or host application has been supplied. Run `php artisan migrate`, `php artisan route:list`, and the manual login/API checks above in a local Laravel installation before presenting it as tested.

## Original project safety
All work is isolated on the `laravel-native-starter` branch. The original root dashboard and production demo branch are not modified.
