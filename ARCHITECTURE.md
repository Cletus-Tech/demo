# Architecture (Stage 1)

```
Browser (static files in app/)                      Supabase (your project)
┌──────────────────────────────┐   HTTPS   ┌────────────────────────────────────────────┐
│ login.html / dashboard.html  │──────────▶│ Auth (email + password)                     │
│ js/api.js  (all backend calls)│          │ Postgres                                    │
│ supabase-js (public anon key)│           │   tables  + Row Level Security (RLS)        │
└──────────────────────────────┘           │   SQL functions = the "server-side" layer   │
                                           └────────────────────────────────────────────┘
```

## Why no framework or build step
The existing `dashboard.html` was kept as-is (design, chart engine, trading panel, CONFIG-driven navigation) and wired to
the backend. A plain static site needs no Node build, is easy for a beginner to host, and is easy to hand over.
React/Vite can still be introduced later if the client's reference design makes it worthwhile.

## The security model in one paragraph
The browser holds only the **public** anon key. It can **read its own rows** and call a short list of **database functions**.
It cannot insert, update or delete anything in money tables. Every action that moves money (`place_spot_order`,
`place_swap`, `open_leveraged_position`, `close_position`, `settle_my_positions`, `demo_deposit`, `demo_withdraw`,
`reset_demo_account`) runs inside Postgres as `SECURITY DEFINER`: it finds the user from the login token (never from a
parameter), checks the account is active, validates every input, takes the price from `market_prices` (the browser can
never send a price), and writes **ledger entries**. A trigger applies each ledger entry to the wallet.

## Tables
| Table | Purpose | Client access |
|---|---|---|
| `profiles` | one row per user: name, role, status, referral code | read own; edit only name, phone, country, language |
| `platform_settings` | non-secret limits and demo configuration | read |
| `assets`, `market_prices` | tradable assets; prices (`source` = `demo` for simulated) | read |
| `wallets` | current balance per user and asset | read own |
| `ledger_entries` | **append-only** record of every balance change | read own |
| `orders`, `positions` | spot/swap/leveraged history and open/closed positions | read own |
| `notifications` | in-app notifications written by the server | read own; may set `read_at` |
| `referrals` | who referred whom (rewards come in Stage 4) | read own |
| `audit_logs` | **append-only** record of sensitive actions | admins only |

## Guarantees enforced by the database itself
1. Wallet balance changes **only** through a ledger insert (a trigger guard refuses any other write, even from the SQL editor).
2. Ledger and audit rows cannot be updated, deleted or truncated.
3. Balances cannot go below zero (CHECK constraint, row-locked update).
4. `mode = 'demo'` is a CHECK constraint on ledger, orders and positions: real-money rows are impossible until a future
   migration deliberately removes it.
5. Role and status can only change through `admin_set_role` (superadmin only, never yourself) / `admin_set_status`, or by the
   database owner. Every change is audit-logged by a trigger.
6. Users with financial history cannot be hard-deleted (foreign keys). Suspend instead.
7. `select * from public.v_ledger_integrity;` must always return zero rows (wallet = sum of ledger).

## Ledger design (an honest note)
It is an **append-only, single-entry ledger** with a `group_id` that ties together the legs of one action (for example the USD
debit and the BTC credit of a buy). The wallet is a trigger-maintained running total and `v_ledger_integrity` proves they agree.
It is *not* a strict double-entry system with a counter-party account; that can be added when real custody is introduced.

## Demo market
`demo_refresh_prices()` random-walks the `demo` prices (at most once per 5 seconds, gently pulled back to an anchor price).
All users share the same simulated prices. The chart's *history* is generated in the browser for illustration and is labelled as such.
Stage 2 replaces this with real market-data providers called from server-side code, keeping API keys secret.

## Known limits of Stage 1
- Take-profit, stop-loss, liquidation and time limits are enforced when the user's browser polls (`settle_my_positions`).
  A background job will take over in Stage 2.
- Deposits and withdrawals are **demo ledger entries** with limits. Real payment workflows (with admin approval) are Stage 3.
- Tables for deposits, withdrawals, investment plans, staking, copy trading, cards and support tickets arrive in the stage that builds them.
- Only English text exists; the language menu is still a placeholder.

## Adding things later (rule)
Every new table gets RLS in the same migration, and every new function must be added to a grants migration that follows the
pattern in `0009`. `node scripts/static-checks.js` fails if a table lacks RLS or an unexpected function becomes callable.
