# Master Brokerage Platform: Stage 1 (Foundation)

A **demo / practice** trading platform: a static web frontend (your existing dashboard, preserved) plus a Supabase backend
with authentication, row-level security, wallets, an append-only ledger, server-side trading functions and an audit log.

**Everything is demo.** Prices are simulated, funds are practice funds, and no real money is held or moved.
Real payments, custody or trading require a licensed provider and are intentionally not implemented.

## What is in the box
```
app/                     the website (upload this folder to any static host)
  index.html             routes to login / dashboard / setup check
  login.html             sign in, create account, forgot password
  reset-password.html    set a new password from the emailed link
  dashboard.html         your original dashboard, now connected to the database
  setup-check.html       live connection + security self-test
  js/config.js           the ONLY file you edit (Supabase URL + anon key)
  js/supabase-client.js  creates the client, refuses secret keys
  js/api.js              every backend call
supabase/
  migrations/0001..0009  database schema, RLS, functions, lockdown
  setup_all.sql          the same migrations in ONE file (paste this)
  tests/rls_tests.sql    security test script (run in the SQL Editor)
docs/                    SUPABASE-SETUP.md, ARCHITECTURE.md, STAGE-1-REPORT.md
scripts/                 build-setup-all.js, generate-config.js, static-checks.js
tests/                   ui-test.py + fake-supabase.js (browser test without a real project)
.env.example             placeholders only (optional)
```

## Quick start
1. Follow **docs/SUPABASE-SETUP.md** (about 20 minutes, free).
2. `cd app && python3 -m http.server 8000`, then open http://localhost:8000
3. Open **/setup-check.html** and confirm every line is PASS.
4. Run **supabase/tests/rls_tests.sql** in the SQL Editor.

## Commands (optional; Node 18+ for the scripts)
| Command | What it does |
|---|---|
| `npm run build:sql` | regenerate `supabase/setup_all.sql` from the migrations |
| `npm run check` | static security checks (RLS on every table, grants, no secrets in `app/`) |
| `npm run config` | write `app/js/config.js` from `.env` or environment variables |
| `npm run serve` | local web server on port 8000 |
| `npm run test:ui` | browser test against a fake backend (needs Python + `playwright` + Chromium) |

## Deploying
Upload the `app/` folder to Netlify, Cloudflare Pages, GitHub Pages or Vercel (publish directory: `app`). Then add the live
address in Supabase under Authentication > URL Configuration. The anon key in `config.js` is public by design; the database
rules are what protect your data. **Never** put a service_role/secret key in `app/`.

## Status
See **docs/STAGE-1-REPORT.md** for what was built, what was tested (and how), and what still needs your Supabase setup.
