# Laravel Brokerage Dashboard

A reusable Laravel Blade brokerage dashboard package based on the client's supplied reference screenshots. The interface retains the existing dark dashboard layout and is connected to a Laravel-native, authenticated demo API.

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
- Profile editing, notification list/read endpoints, referral-code sign-up attribution, and service enquiry submission/history.
- Admin page for account roles/status and service-enquiry status.

## Install in a fresh Laravel 12 application
1. Create a Laravel project and configure its database in `.env`.
2. Copy/merge the contents of this `laravel-app` folder into the Laravel project root. Do not blindly overwrite existing host-project files.
3. Install API routing and Sanctum if not already installed:
   ```bash
   php artisan install:api
   ```
4. In Laravel 12, enable Sanctum's stateful API middleware in `bootstrap/app.php`. The application's configuration should contain this middleware callback (merge the call into the existing callback rather than replacing other middleware):
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
10. Copy `tests/Feature/BrokerApiTest.php` into the host application's `tests/Feature/` directory, then run `php artisan view:cache`, `php artisan route:list --except-vendor` and `php artisan test`.

## Demo seed data and optional demo account

The brokerage migration creates the five baseline demo assets. The package also includes an idempotent seeder that restores those clearly labelled simulated market rows:

```bash
php artisan db:seed --class='Database\Seeders\BrokerDemoSeeder'
```

To create an optional ordinary demo login during seeding, configure these environment variables on the host (never commit the password to Git):

```dotenv
BROKER_DEMO_USER_NAME="Demo Trader"
BROKER_DEMO_USER_EMAIL="demo@example.com"
BROKER_DEMO_USER_PASSWORD="use-a-unique-password-at-least-12-characters"
```

Then run the same seeder command. The seeder creates the account only when the email does not already exist, never resets an existing password or account status, and never grants an administrator role. Without both email and password variables it seeds assets only. The demo account is for simulated operations; it has no real funds or payment capability.

## API routes
All browser API endpoints use `auth:sanctum` and same-origin session authentication. The browser adapter initializes the Sanctum CSRF cookie before write requests.

- `GET /api/broker/state` — profile, assets, wallet balances, positions and transactions.
- `GET /api/broker/prices` — lightweight quote-only response used by the five-second dashboard refresh; it does not reload wallet/history data.
- `POST /api/broker/prices/refresh` — move seeded prices using a small random simulated demo tick. A database lock limits the shared market to one tick every five seconds across all browsers.
- `POST /api/broker/transactions` — demo USD deposit/withdrawal or USD-valued buy/sell/convert. For buy/sell/convert, send `quote_amount_usd`; do not send a client-computed token quantity or price.
- `POST /api/broker/positions` — open a demo leveraged position using `margin_usd`; the server calculates quantity and locked margin.
- `POST /api/broker/positions/{id}/close` — manually close an owned position.
- `POST /api/broker/positions/settle` — evaluate configured TP/SL and expiry conditions.
- `POST /api/broker/reset` — clear demo balances and close open demo positions.
- `GET /api/broker/notifications`, `POST /api/broker/notifications/read`.
- `PATCH /api/broker/profile`.
- `GET /api/broker/referrals` — the signed-in user's referral code and referred sign-ups; no reward payouts are enabled.
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

For buy/sell/convert and leveraged positions, the server reads the current seeded demo price and calculates asset quantity itself. The browser does not submit an execution price or authoritative quantity. Asset rows and user wallets are locked before demo trades update balances. Position settlement locks the position, then its asset quote, then the user's USD wallet; database transaction retries reduce transient lock conflicts. A lightweight quote endpoint avoids reloading full account state on every chart tick, and a shared five-second database cooldown prevents multiple open browsers from repeatedly moving the same demo market.

## Demo-only limitations
- Market prices are seeded demonstration values and moved with simulated random ticks; USD remains fixed at 1 as the accounting quote currency. No licensed live exchange feed is connected. The chart's older candles are generated illustrations, not historical exchange data.
- Deposits and withdrawals only alter simulated demo balances. There is no payment gateway, real-money settlement, crypto custody or live trading.
- Admin access is role-gated; role changes must be performed by a superadmin.
- Referral sign-up attribution is recorded, but reward calculation/payouts, real customer support chat, live market data and external financial services are not implemented. Service cards record enquiries only.
- This is a reusable integration package, not a complete Laravel framework distribution. CI now merges it into a clean Laravel 12 host and runs feature tests; the eventual client host, browser-session cookie settings, production database locking and deployment still need their own smoke test.

## Verification status
Two GitHub Actions workflows run on changes to this package. The static workflow checks PHP source syntax and the browser adapter's JavaScript syntax. The integration workflow provisions a fresh Laravel 12 host with SQLite, installs Sanctum, merges the package, compiles the Blade views, lists routes, runs migrations and the feature suite, then starts the host and runs a headless Chromium browser smoke test. The browser test registers a user, loads the dashboard and chart, performs a demo deposit and server-priced BTC buy through the CSRF/session adapter, checks 390px and 360px layouts for horizontal overflow, and signs out. The workflow uses Ubuntu 24.04 for Playwright browser compatibility. These checks do not deploy the application or prove production database concurrency, real client-domain cookie settings or hosting behaviour. Those still require a smoke test in the eventual host environment. Do not use real funds.


## Automated integration tests

The package includes feature tests in `tests/Feature/BrokerApiTest.php`. Copy that file into the host application's `tests/Feature/` directory after merging the package, then run:

```bash
php artisan view:cache
php artisan route:list --except-vendor
php artisan test
```

The optional browser smoke test is in `tests/browser/dashboard-smoke.mjs`. With the Laravel host running on the same origin, install Playwright and Chromium, then run:

```bash
npm install --no-save playwright@1.56.1
npx playwright install chromium
BROKER_BASE_URL=http://127.0.0.1:8000 node tests/browser/dashboard-smoke.mjs
```

The tests cover registration/login/logout and dashboard session protection, the Sanctum CSRF-cookie route, suspended-account session denial, idempotent demo seeding and safe optional demo-user creation, server-authoritative trade quotes, buy/sell/convert accounting, overspending rejection, persisted trade/position history, margin reservation and realized long/short demo P/L release, TP/SL validation and settlement, USD quote stability and shared price-tick throttling, notification and service-request ownership, cross-account position access, referral privacy, and admin role restrictions.

GitHub Actions also creates a fresh Laravel 12 host application, installs Sanctum API support, merges this package, compiles the Blade views, lists routes, runs migrations, seeds demo data and executes the feature suite. It then runs the Playwright smoke test in Chromium at desktop and mobile widths. These integration jobs are the verification gate for changes to this package. The authoring container has PHP but no Composer or network access to provision Laravel locally, so the Laravel runtime checks run in GitHub Actions.

## Accounting and quote safeguards

- USD is the fixed accounting quote currency and is never randomly moved with simulated market ticks. If a test or operator changes its stored price, the next demo price refresh restores it to 1.
- Leveraged demo positions reject fiat-category assets.
- Leverage precision is limited to the two decimal places stored by the database.
- TP/SL/expiry evaluation and settlement now use the same locked position and asset quote inside one database transaction, preventing the trigger decision and settlement price from drifting apart.
