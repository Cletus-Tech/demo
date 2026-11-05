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
- Demo deposit, withdrawal, buy, sell, convert, open/close position, timed expiry, TP/SL settlement and demo account reset endpoints.
- Profile editing, notification list/read endpoints, service enquiry submission/history.
- Admin page for account roles/status and service-enquiry status.

## Install in a fresh Laravel 11/12 application
1. Create a Laravel project and configure its database in `.env`.
2. Copy/merge the contents of this `laravel-app` folder into the Laravel project root. Do not blindly overwrite existing host-project files.
3. Install API routing and Sanctum if not already installed:
   ```bash
   php artisan install:api
   ```
4. In Laravel 11/12, enable Sanctum's stateful API middleware in `bootstrap/app.php`. Merge this into the existing `withMiddleware` configuration:
   ```php
   use Illuminate\\Foundation\\Configuration\\Middleware;

   ->withMiddleware(function (Middleware $middleware): void {
       $middleware->statefulApi();
   })
   ```
   Keep the application's existing middleware configuration and add the stateful call; do not replace unrelated middleware.
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
- `POST /api/broker/transactions` — demo deposit, withdrawal, buy, sell or conversion.
- `POST /api/broker/positions` — open demo leveraged position.
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
Example position payload:
```json
{ "symbol": "BTC", "side": "buy", "quantity": 0.01, "leverage": 2, "duration_seconds": 120 }
```

## Demo-only limitations
- Market prices are seeded demonstration values; no live exchange feed is connected.
- Deposits and withdrawals only alter simulated demo balances. There is no payment gateway, real-money settlement, crypto custody or live trading.
- Admin access is role-gated; role changes must be performed by a superadmin.
- Referral reward processing, real customer support chat, live market data and external financial services are not implemented.
- This package is an integration foundation. The dashboard adapter covers the main trading and account flows, but a host-app integration and full regression test are still required before client handover.

## Verification status
The repository changes have been committed to branch `laravel-native-starter`. No Laravel host application has been supplied or booted in this workspace, so migrations, `route:list`, login, browser flows and database accounting have **not** been runtime-tested here. Run those checks in a fresh Laravel host project before presenting this as production-ready. Do not use real funds.
