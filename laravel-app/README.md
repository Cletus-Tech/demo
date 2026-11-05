# Laravel Dashboard Integration Starter

This is a Laravel integration starter containing the existing brokerage dashboard Blade view plus Laravel-native session login and registration routes/controllers.

## Important scope
- The original dashboard markup, styles and browser-side interactions are preserved in `resources/views/dashboard.blade.php`.
- Login and registration use Laravel's `Auth` facade, password hashing, CSRF protection, session regeneration and the host application's `users` table.
- The dashboard route is protected by Laravel's `auth` middleware.
- The current dashboard JavaScript still depends on the existing browser-side API/Supabase integration. This starter does **not** claim that wallet, deposits, withdrawals, swaps, orders, positions or admin operations have been migrated to Laravel controllers/database.
- The client's own Laravel project has not yet been supplied. Routes, models, middleware, menu structure, asset paths and database schema must be reconciled against that project before final integration.

## Install into an existing Laravel application
1. Copy the contents of this folder into the root of a Laravel application, preserving paths.
2. Ensure the standard Laravel `users` migration and `App\\Models\\User` model exist.
3. Merge the routes from `routes/web.php` into the host application's routes file (do not overwrite existing routes).
4. Ensure `DashboardController`, `LoginController` and `RegisterController` are in the stated namespaces.
5. Copy the previously supplied `laravel-conversion/public/js/` assets into the host app's `public/js/` directory and configure its public Supabase values if retaining the current API adapter.
6. Configure `.env`, then run `php artisan key:generate` (new app only), `php artisan migrate`, and `php artisan serve`.

## Test
- Register a test user at `/register`.
- Sign out and sign in at `/login`.
- Confirm unauthenticated visits to `/dashboard` redirect to login.
- Confirm successful login redirects to the protected dashboard.

## Next integration requirement
Obtain the client's working Laravel project/repository. The final pass must map the dashboard to their actual menu/routes and migrate each data/action contract to their backend rather than duplicating their existing systems.

## Demo / financial safety
This is a development integration starter. It is not a live brokerage or payment system. Do not use real funds or present simulated values as executable trading.
