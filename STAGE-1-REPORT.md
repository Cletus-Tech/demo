# Stage 1 report: Foundation

**Status: built and partly tested. NOT yet verified against a real Supabase project.** That verification needs you
(see "What I need from you"). Until you complete it, treat the backend as unproven.

## Delivered
| Item | Where |
|---|---|
| Updated dashboard (design, chart engine, trade panel, CONFIG-driven nav preserved) | `app/dashboard.html` |
| Authentication (sign in, sign up, forgot/reset password, sign out, route protection) | `app/login.html`, `reset-password.html`, `js/` |
| Database schema, 9 migrations + one-paste file | `supabase/migrations/`, `supabase/setup_all.sql` |
| RLS policies on every table, column-level grants, lockdown of default access | migrations 0001-0005, 0009 |
| Profiles, roles (user/support/admin/superadmin), suspension | 0001, 0008 |
| Wallets + append-only ledger + integrity view | 0003 |
| Server-side demo trading, deposit, withdraw, reset | 0006 |
| Audit log + automatic audit of role/status changes | 0004 |
| Notifications and referrals (tables + signup hook) | 0004, 0007 |
| Connection self-test page | `app/setup-check.html` |
| RLS security test script | `supabase/tests/rls_tests.sql` (60+ checks) |
| `.env.example`, README, setup guide, architecture notes | repo root, `docs/` |

## What changed in your dashboard (and what did not)
**Unchanged:** layout, styling, chart engine, drawing tools, trade panel, CONFIG-driven navigation, sidebar groups, responsive behaviour.
**Changed (backend wiring):**
- Balances, positions, history and notifications now come from the database; `localStorage` is no longer used for them.
- Buy, sell, convert, leverage, TP/SL, deposit, withdraw and close call server functions. The server re-validates everything.
- Prices come from the server (still **simulated**, labelled DEMO). The browser can no longer invent prices or balances.
- "Edit demo balances" was **removed** (it let users set any balance). It is replaced by "Reset demo account", which is recorded in the ledger.
- Holdings are now stored in units and re-valued as prices move (the prototype stored fixed dollar amounts).
- Added: demo-mode banner, Sign out, the account email in the menu. Settings and not-yet-built menu items show a "coming in a later stage" message.
- The page refuses to run (and sends you to the setup check) until Supabase is configured. There is no offline fake mode.

## Testing: what was actually done
| Test | Result | Honest scope |
|---|---|---|
| `node scripts/static-checks.js` (RLS on all 11 tables, grants, SECURITY DEFINER, no secrets in `app/`, balanced SQL quoting) | **all pass** | Static analysis only; it does not execute SQL |
| `python3 tests/ui-test.py` (headless Chromium, 27 checks: redirects, signup, trading, overspend, leverage open/close, deposit/withdraw, notifications, reset, sign out, 375px phone layout, secret-key refusal) | **27/27 pass** | Runs against a **fake** backend written in JavaScript. It proves the page logic, not the real database |
| JavaScript syntax check of every page script | pass | |
| **The SQL migrations executed on real Postgres** | **NOT DONE** | My environment has no Postgres and no network. The SQL was reviewed carefully but has never been run |
| **`rls_tests.sql` executed** | **NOT DONE** | It is written and waiting for you to run it (Setup guide Step 10) |
| Real Supabase Auth, email delivery, hosting | **NOT DONE** | Needs your project |

Possible outcomes when you run `setup_all.sql`: it succeeds, or it reports a syntax/permission error that I fix quickly.
Please send me the exact message if so. Do not edit the SQL yourself.

## Decisions and deviations (please confirm)
1. **No React/Vite.** I kept the existing static dashboard rather than rewrite it (you asked to preserve it). Simpler for a beginner to host.
2. **"Server-side" = Postgres functions, not Edge Functions**, for Stage 1. They need no CLI or deployment. Edge Functions will be used in Stage 2 for market-data providers that need secret API keys.
3. **Ledger is append-only single-entry with group ids**, not strict double-entry as I first described. Reasoning is in `docs/ARCHITECTURE.md`.
4. **Tables deferred** to the stage that builds them: deposits/withdrawals (Stage 3), investment/staking/copy-trading/cards/support tickets (Stage 4).
5. **Demo top-ups are allowed but capped** (`demo_max_topup_usd`, `demo_max_usd_balance` in `platform_settings`) so the demo still lets people practise without unlimited money creation.

## Known limitations
- TP/SL/liquidation/time-limit are checked when the browser polls, not by a background job (Stage 2).
- Chart history is generated in the browser for illustration. Only the *current* price comes from the server.
- All users share one simulated price series; any signed-in client can advance it (rate-limited to once per 5 s).
- Hard-deleting a user with history is blocked by design; suspend them instead.
- Only English is wired. Several menu items are placeholders until their stage.
- Supabase's built-in email sender is heavily rate-limited; custom SMTP is needed before launch.

## Important: demo vs real money
Nothing here is, or should be presented as, a real brokerage. Before any real deposits, withdrawals, leverage, copy trading, mining,
real-estate or card products are offered to the public, your client needs the licences and licensed partners that apply in their and
their users' jurisdictions. Stage 1 deliberately makes real-money records impossible at the database level (`mode = 'demo'` checks).

## What I need from you
1. Complete `docs/SUPABASE-SETUP.md` Steps 1 to 9 and tell me the result of `/setup-check.html` (screenshot).
2. Run `supabase/tests/rls_tests.sql` (Step 10) and send me the full message.
3. Screenshots of the Tradex Surge dashboard and its other pages (logged in), phone and desktop, for Stage 2 design matching.
4. Your client's intended use and jurisdiction (demo/education, or real money through a named licensed partner).
5. Before Stage 2: approval of free-tier market-data providers (my suggestion: CoinGecko for crypto, and a free tier of a stocks/forex API). I will not sign up for anything paid.

I will not start Stage 2 until you approve Stage 1.
