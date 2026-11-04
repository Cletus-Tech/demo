# Demo Broker — Brokerage Platform Foundation

This repository contains the existing client-approved brokerage-style dashboard, connected to Supabase for authentication, account data, demo wallets, ledger entries, orders, positions, referrals, notifications, and administration.

## Important operating mode

The current platform is a **demo/practice environment**:
- Balances and deposits/withdrawals are simulated practice funds.
- Market prices are marked as demo/simulated; they are not exchange feeds.
- Spot orders, swaps, and leveraged positions are processed by database functions against demo wallets.
- Service products (cards, custody, signals, copy trading, staking, etc.) are enquiry workflows, not activated financial products.
- No real money, crypto custody, or live exchange orders are processed.

A production launch requires separately integrating and testing licensed payment, custody, KYC/AML, market-data, and brokerage/exchange providers, plus legal/compliance approval. Provider credentials must never be committed to this public repository.

## Main files

- `index.html` — entry / route page
- `login.html` — registration, sign-in and password recovery
- `reset-password.html` — password reset callback
- `dashboard.html` — existing responsive dashboard and trading interface
- `admin.html` — protected staff console
- `setup-check.html` — connection and security self-check
- `config.js` — public Supabase project URL and publishable key only
- `supabase-client.js` — Supabase client/session setup
- `api.js` — browser-to-database API calls
- `setup_all.sql` — consolidated initial database setup
- `migrations/` — incremental database migrations

## Deployment

The site is deployed from the repository's `main` branch through GitHub Pages.

Live site: https://cletus-tech.github.io/demo/

After changing authentication redirect URLs or the hosting domain, update Supabase Authentication > URL Configuration to include the deployed site and the login/reset-password callback pages.

## Database changes

The connected Supabase project is the **Demo Broker** project. Do not run `setup_all.sql` again on an already initialized database. Apply only migrations that have not already been applied, then run the setup check and database security advisors.

## Validation

1. Open `setup-check.html` while signed in.
2. Confirm the authenticated trading-function validation rejects the intentionally invalid test order.
3. Confirm the profile, service request access, demo wallets, and demo market prices checks.
4. Use a dedicated authorized admin/superadmin account to test `admin.html`.
5. Test demo transactions with practice funds only and verify resulting ledger/order/position records.

Never place a Supabase `service_role` or secret key in browser code.
