# Laravel Brokerage Dashboard

A reusable Laravel Blade brokerage dashboard package based on the client's supplied reference screenshots. The interface retains the existing dark dashboard layout and is now being connected to a Laravel-native, authenticated demo API.

## Included in this package
- Blade dashboard with responsive styling and existing chart/trade interactions.
- Laravel session login, registration and logout.
- Auth-protected dashboard and admin routes.
- Laravel browser adapter at `public/js/broker-api.js`; the dashboard no longer loads the Supabase browser client.
- Migrations and Eloquent models for assets, wallets, transactions, leveraged positions, notifications and service requests.
- User role, account status, phone and country fields.
- Demo market assets: BTC, ETH, SOL, USD and EUR.
- Demo USD deposit/withdrawal and USD-valued buy/sell/convert endpoints; the server calculates quantities from locked current demo prices.
- Open/close leveraged positions using a USD margin budget, timed expiry, TP/SL settlement and demo account reset.
- Profile editing, notification list/read endpoints, service enquiry submission/history.
- Admin page for account roles/status and service-enquiry status.

## Install in a fresh Laravel 11/12 application
1. Create a Laravel project and configure its database in `.env`.
2. Copy/merge the contents of this `laravel-app` folder into the Laravel project root. Do not blindly overwrite existing host-project files.
3. Install API routing and Sanctum if not already installed:
   ```bash
   php artisan install:api
   ```
4. In Laravel 11/12, enable Sanctum's stateful API middleware in `bootstrap/app.php`. The application's configuration should contain this middleware callback (merge the call into the existing callback rather than replacing other middleware):
   ```php
   use Illuminate\\Foundation\\Configuration\\Middleware;

   // Inside Application::configure(...):
   ->withMiddleware(function (Middleware $middleware): void {
       $middleware->statefulApi();
   })
   ```
   Ensure `.env` has the host used by your browser in `SANCTUM_STATEFUL_DOMAINS`, for example `localhost,localhost:8000,127.0.0.1,127.0.0.1:8000` for local development. Keep the dashboard and API on the same origin for this package's session-based browser adapter.
5. Merge the package's `routes/web.php` and `routes/api.php` entries into the host route files. Keep existing application routes. Ensure `routes/api.php` is loaded by Laravel.
6. Confirm the host app uses the standard `App\\Models\\User` authenticatable model and standard `users` table with `name`, `email` and `password` columns. The migrations add brokerage-specific user columns.
7. Run:
   ```bash
   php artisan key:generate
   php artisan migrate
   php artisan route:list
   php artisan serve
   ```
8. Visit `/register`, create a test user, then visit `/dashboard`. Demo USD can be added using the dashboard's Deposit action; it is not real money.
9. To enable the first administrator, after creating the intended owner account, use Tinker:
   ```bash
   php artisan tinker
   ```
   ```php
   App\\Models\\User::where('email', 'owner@example.com')->update(['role' => 'superadmin', 'account_status' => 'active']);
   ```
   Replace the email with the account you control. Do not grant admin roles to untrusted users.

## API routes
All browser API endpoints use `auth:sanctum` and same-origin session authentication. The browser adapter initializes the Sanctum CSRF cookie before write requests.

- `GET /api/broker/state` — profile, assets, wallet balances, positions and transactions.
- `POST /api/broker/prices/refresh` — move seeded prices using a small random simulated demo tick.
- `POST /api/broker/transactions` — demo USD deposit/withdrawal or USD-valued buy/sell/convert. For buy/sell/convert, send `quote_amount_usd`; do not send a client-computed token quantity or price.
- `POST /api/broker/positions` — open a demo leveraged position using `margin_usd`; the server calculates quantity and locked margin.
- `POST /api/broker/positions/{id}/close` — manually close an owned position.
- `POST /api/broker/positions/settle` — evaluate configured TP/SL and expiry conditions.
- `POST /api/broker/reset` — clear demo balances and close open demo positions.
- `GET /api/broker/notifications`, `POST /api/broker/notifications/read`.
- `PATCH /api/broker/profile`.
- `GET/POST /api/broker/services`.

Example transaction payload:
```json
{ "type": "deposit", "symbol": "USD", "amount": 1000 }
```
Example buy payload:
```json
{ "type": "buy", "symbol": "BTC", "quote_amount_usd": 250 }
```
Example conversion payload:
```json
{ "type": "convert", "symbol": "BTC", "to_symbol": "ETH", "quote_amount_usd": 100 }
```
Example leveraged position payload:
```json
{ "symbol": "BTC", "side": "buy", "margin_usd": 100, "leverage": 2, "duration_seconds": 120 }
```

For buy/sell/convert and leveraged positions, the server reads the current seeded demo price and calculates asset quantity itself. The browser does not submit an execution price or authoritative quantity. A stable wallet-lock order and database transaction retries reduce concurrent swap/settlement conflicts.

## Demo-only limitations
- Market prices are seeded demonstration values and moved with simulated random ticks; no licensed live exchange feed is connected.
- Deposits and withdrawals only alter simulated demo balances. There is no payment gateway, real-money settlement, crypto custody or live trading.
- Admin access is role-gated; role changes must be performed by a superadmin.
- Referral tracking/reward processing, real customer support chat, live market data and external financial services are not implemented. Service cards record enquiries only.
- This package is an integration foundation. The dashboard adapter covers the main trading and account flows, but a host-app integration and full regression test are still required before client handover.

## Verification status
GitHub Actions runs PHP/JavaScript syntax checks and creates a disposable Laravel 12 + SQLite host to run package feature tests on pushes to this branch. The repository changes have been committed to `laravel-native-starter`. The CI integration job exercises the package in a disposable Laravel 12 + SQLite host. It does not deploy or include a production host. Browser-session behaviour, production database locking characteristics, deployment configuration and any client-specific integration still require verification in the eventual hosting environment. Do not use real funds.


## Automated integration tests

The package includes feature tests in `tests/Feature/BrokerApiTest.php`. Copy that file into the host application's `tests/Feature/` directory after merging the package, then run:

```bash
php artisan view:cache
php artisan route:list --except-vendor
php artisan test
```

The tests cover demo buy/sell/convert accounting, rejection of overspending, reserved leveraged margin and realized demo P/L release, USD quote-currency stability, fiat leveraged-position rejection, notification ownership/read state, cross-account position access, and admin role restrictions.

GitHub Actions also creates a fresh Laravel 11 and Laravel 12 host application, installs Sanctum API support, merges this package, compiles the Blade views, lists routes and runs the feature suite. These integration jobs are the verification gate for changes to this package. The local execution environment used to author this package did not include Composer or a Laravel host application, so local Laravel runtime tests could not be run.

## Accounting and quote safeguards

- USD is the fixed accounting quote currency and is never randomly moved with simulated market ticks. If a test or operator changes its stored price, the next demo price refresh restores it to 1.
- Leveraged demo positions reject fiat-category assets.
- Leverage precision is limited to the two decimal places stored by the database.
- TP/SL/expiry evaluation and settlement now use the same locked position and asset quote inside one database transaction, preventing the trigger decision and settlement price from drifting apart.
