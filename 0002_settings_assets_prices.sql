-- =====================================================================
-- 0002  Platform settings, assets and market prices
-- =====================================================================

-- Non-secret platform configuration. NEVER store API keys or passwords here:
-- every signed-in user can read this table.
create table public.platform_settings (
  key         text primary key,
  value       jsonb not null,
  description text,
  updated_at  timestamptz not null default now(),
  updated_by  uuid
);

insert into public.platform_settings (key, value, description) values
  ('platform_mode',               '"demo"',   'Must stay "demo" until a licensed provider is connected.'),
  ('demo_starting_balances_usd',  '{"BTC":5000,"ETH":2000,"USD":3000,"SOL":2000,"AAPL":1000}',
                                              'USD value of each asset granted to a new or reset demo account.'),
  ('demo_volatility',             '0.006',    'Size of each simulated price move (fraction, e.g. 0.006 = 0.6%).'),
  ('demo_price_interval_seconds', '5',        'Minimum seconds between simulated price moves.'),
  ('demo_max_topup_usd',          '100000',   'Largest single demo deposit.'),
  ('demo_max_usd_balance',        '1000000',  'Demo deposits are refused above this USD balance.'),
  ('max_leverage',                '100',      'Highest leverage allowed.'),
  ('max_order_usd',               '10000000', 'Largest single order or margin amount.');

create or replace function public._setting_num(p_key text, p_default numeric)
returns numeric language sql stable security definer set search_path = public as $$
  select coalesce(
    (select (value #>> '{}')::numeric from public.platform_settings where key = p_key),
    p_default)
$$;

create table public.assets (
  symbol      text primary key check (symbol = upper(symbol)),
  name        text not null,
  category    text not null check (category in
                ('crypto','stocks','fiat','forex','etf','commodity','real_estate','other')),
  is_active   boolean not null default true,
  is_tradable boolean not null default true,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now()
);

-- source = 'demo' means the price is SIMULATED. Stage 2 adds 'live'.
create table public.market_prices (
  symbol      text primary key references public.assets (symbol) on delete cascade,
  price       numeric(28,10) not null check (price > 0),
  demo_anchor numeric(28,10) not null check (demo_anchor > 0),
  source      text not null default 'demo' check (source in ('demo', 'live')),
  updated_at  timestamptz not null default now()
);

insert into public.assets (symbol, name, category, sort_order) values
  ('BTC',  'Bitcoin',              'crypto', 1),
  ('ETH',  'Ethereum',             'crypto', 2),
  ('USD',  'United States Dollar', 'fiat',   3),
  ('SOL',  'Solana',               'crypto', 4),
  ('AAPL', 'Apple',                'stocks', 5);

insert into public.market_prices (symbol, price, demo_anchor, source) values
  ('BTC',  80000, 80000, 'demo'),
  ('ETH',   2500,  2500, 'demo'),
  ('USD',      1,     1, 'demo'),
  ('SOL',    100,   100, 'demo'),
  ('AAPL',   200,   200, 'demo');

alter table public.platform_settings enable row level security;
alter table public.assets            enable row level security;
alter table public.market_prices     enable row level security;

create policy settings_read on public.platform_settings for select to authenticated using (true);
create policy assets_read   on public.assets            for select to authenticated using (true);
create policy prices_read   on public.market_prices     for select to authenticated using (true);
-- No insert/update/delete policies: clients cannot change these tables.
