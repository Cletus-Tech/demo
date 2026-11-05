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
php artisan migrate --seed
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
- Laravel session registration/login/logout.
- Laravel API endpoints for account state, simulated prices, demo deposit/withdraw/buy/sell/convert, leveraged positions, TP/SL/expiry settlement, demo reset, profile, notifications and service enquiries.
- Role-gated admin console for users and service enquiry workflow.

## Important integration notes
- The dashboard uses `public/js/broker-api.js`; it does not load the Supabase browser SDK.
- Laravel Sanctum stateful middleware is enabled in `bootstrap/app.php` for same-origin session-authenticated API requests.
- Default local DB is SQLite. Set `DB_CONNECTION=mysql` and the `DB_*` values in `.env` for MySQL hosting.
- Do not copy any `.env` or secret key into Git. Configure `APP_KEY`, DB credentials and `APP_DEBUG=false` on the server.
- Point the web server document root to this folder's `public/` directory. Do not expose the project root.
- GitHub Pages and static Vercel output cannot execute Laravel PHP. Deploy this application to PHP hosting, a VPS, or Laravel Cloud, then connect the intended domain.

## Demo-only scope
This conversion still simulates prices and funds. It is not connected to real exchange prices, payment rails, custody, or live brokerage execution. No real deposits or withdrawals are processed. Real financial operations require regulated providers, compliance and separate security review.

## Verification
The repository contains syntax checks, but this workspace has not executed Composer, Laravel migrations or browser tests against a running PHP/database server. Run `composer install`, `php artisan migrate`, `php artisan route:list`, then test signup, login, wallet operations, trades, TP/SL, logout and admin access before client handover.
