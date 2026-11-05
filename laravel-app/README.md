# Demo Broker — Laravel conversion

This is the Laravel application version of the original Demo Broker project. The original static/Supabase demo remains untouched on `main`; this branch preserves the same dark dashboard UI and moves browser account operations to Laravel controllers, Eloquent models, database transactions and session authentication.

## Requirements
- PHP 8.2+
- Composer 2
- SQLite for local testing (included with PHP PDO SQLite) or MySQL 8+

## Run locally
```bash
cd laravel-app
composer install
cp .env.example .env
php artisan key:generate
# SQLite: create the empty database file if it does not exist
# Windows PowerShell: New-Item -ItemType File database/database.sqlite -Force
php artisan migrate
php artisan serve
```
Open `http://127.0.0.1:8000/register` and create a test account. After the first account is created, promote only the owner account:
```bash
php artisan tinker
```
```php
App\\Models\\User::where('email', 'owner@example.com')->update(['role' => 'superadmin', 'account_status' => 'active']);
```
Replace the example email with the owner account you control.

## Original functionality retained
- The Blade dashboard is based on the existing original `dashboard.html` structure and visual styling, including the chart, chart toolbar/drawings, assets, account panels, trade form, TP/SL controls, responsive layout and navigation.
- Laravel session registration/login/logout and password reset; every new account receives the original configured demo starting portfolio (USD-value grants for BTC, ETH, USD, SOL and AAPL).
- Unique referral codes, referral-link registration and account referral tracking.
- Laravel API endpoints for account state, simulated prices, demo deposit/withdraw/buy/sell/convert, leveraged positions, TP/SL/expiry settlement, demo reset, profile, notifications and service enquiries.
- Role-gated admin console for users and service enquiry workflow.

## Important integration notes
- The dashboard uses `public/js/broker-api.js`; it does not load the Supabase browser SDK.
- Laravel Sanctum stateful middleware is enabled in `bootstrap/app.php` for same-origin session-authenticated API requests.
- Default local DB is SQLite. Set `DB_CONNECTION=mysql` and the `DB_*` values in `.env` for MySQL hosting.
- `config/broker.php` controls the demo starting portfolio and simulated-price cadence. Demo reset restores those configured starting balances and retains transaction history.
- Do not copy any `.env` or secret key into Git. Configure `APP_KEY`, DB credentials and `APP_DEBUG=false` on the server.
- Point the web server document root to this folder's `public/` directory. Do not expose the project root.
- GitHub Pages and static Vercel output cannot execute Laravel PHP. Deploy this application to PHP hosting, a VPS, or Laravel Cloud, then connect the intended domain.

## Demo-only scope
This conversion still simulates prices and funds. It is not connected to real exchange prices, payment rails, custody, or live brokerage execution. No real deposits or withdrawals are processed. Real financial operations require regulated providers, compliance and separate security review.

## Verification
GitHub Actions currently runs Composer validation/install, database migrations, sixteen PHPUnit feature tests (84 assertions), route registration, browser-adapter syntax checks and inline dashboard JavaScript syntax checks. These tests cover demo funding and ledger reconciliation, spot buy/sell, withdrawals, leveraged margin/close, duplicate-request idempotency, reset, referral attribution, password recovery, simulated price throttling, dashboard rendering, user data isolation, admin access and role-change protections. A real PHP-hosted browser acceptance test is still required before production handover.

## PHP hosting deployment checklist
1. Choose hosting with PHP 8.2+, Composer 2, `pdo_mysql`, `mbstring`, `openssl`, `tokenizer`, `xml`, `ctype` and `fileinfo`; create a MySQL database and database user.
2. Upload/clone the repository and run Composer from `laravel-app`: `composer install --no-dev --optimize-autoloader`.
3. Copy `.env.example` to `.env`; set `APP_ENV=production`, `APP_DEBUG=false`, the HTTPS `APP_URL`, a generated `APP_KEY`, `DB_CONNECTION=mysql`, and the host's database credentials. Set `SESSION_SECURE_COOKIE=true` for HTTPS.
4. Set the site's document root to `laravel-app/public` (not the repository root), ensure `storage` and `bootstrap/cache` are writable, then run `php artisan migrate --force`, `php artisan storage:link`, `php artisan config:cache`, `php artisan route:cache` and `php artisan view:cache`.
5. Register the owner account, then promote that account using the Tinker command above. Confirm `/login`, `/register`, `/dashboard`, `/admin`, demo wallet actions and position settlement over HTTPS.
6. Keep the original GitHub Pages demo online until the Laravel host passes acceptance testing. GitHub Pages itself cannot run PHP.
