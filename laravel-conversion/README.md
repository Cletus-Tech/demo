# Laravel Blade dashboard conversion

This folder contains a Laravel Blade view conversion of the existing brokerage dashboard.

## Files
- `resources/views/dashboard.blade.php` — original dashboard markup, styles and interactive JavaScript preserved as a Blade view.
- `public/js/config.js`, `supabase-client.js`, `api.js` — existing browser-side dependencies copied so the converted view can retain its current demo behaviour.

## Install into a Laravel application
Copy:
- `laravel-conversion/resources/views/dashboard.blade.php` to `resources/views/dashboard.blade.php`
- `laravel-conversion/public/js/` contents to `public/js/`

Add a route in `routes/web.php`:
```php
use Illuminate\\Support\\Facades\\Route;

Route::view('/dashboard', 'dashboard')->name('dashboard');
```

Then open `/dashboard`.

## Important scope note
This is a Blade-template conversion, not a rewrite of the backend into Laravel. The existing dashboard JavaScript still calls the current Supabase client/API and retains the existing demo-mode behaviour. Laravel authentication, Eloquent models, controllers, and native Laravel trading endpoints would be a separate backend migration. Do not describe those as completed by this conversion.

The original production files at the repository root are unchanged.
