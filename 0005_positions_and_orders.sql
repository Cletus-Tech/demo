-- =====================================================================
-- 0005  Positions (leveraged trades) and orders
-- Clients can READ their own rows; every write happens in 0006 functions.
-- =====================================================================

create table public.positions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete restrict,
  symbol       text not null references public.assets (symbol),
  side         text not null check (side in ('long','short')),
  margin_usd   numeric(28,10) not null check (margin_usd > 0),
  leverage     int not null check (leverage between 2 and 1000),
  entry_price  numeric(28,10) not null check (entry_price > 0),
  take_profit  numeric(28,10) check (take_profit is null or take_profit > 0),
  stop_loss    numeric(28,10) check (stop_loss is null or stop_loss > 0),
  expires_at   timestamptz,
  status       text not null default 'open' check (status in ('open','closed')),
  close_price  numeric(28,10),
  close_reason text check (close_reason in ('manual','take_profit','stop_loss','liquidated','duration_ended')),
  payout_usd   numeric(28,10),
  pnl_usd      numeric(28,10),
  mode         text not null default 'demo' check (mode = 'demo'),
  opened_at    timestamptz not null default now(),
  closed_at    timestamptz
);
create index positions_user_idx on public.positions (user_id, status);

create table public.orders (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete restrict,
  kind        text not null check (kind in ('spot','swap','leveraged')),
  order_type  text not null default 'market' check (order_type = 'market'),
  side        text not null check (side in ('buy','sell','convert')),
  symbol      text not null references public.assets (symbol),
  from_symbol text references public.assets (symbol),
  amount_usd  numeric(28,10) not null check (amount_usd > 0),
  price       numeric(28,10) not null check (price > 0),
  quantity    numeric(28,10) not null check (quantity > 0),
  leverage    int not null default 1 check (leverage between 1 and 1000),
  status      text not null default 'filled' check (status in ('filled','rejected','cancelled')),
  position_id uuid references public.positions (id),
  group_id    uuid,
  mode        text not null default 'demo' check (mode = 'demo'),
  created_at  timestamptz not null default now()
);
create index orders_user_idx on public.orders (user_id, created_at desc);

alter table public.positions enable row level security;
alter table public.orders    enable row level security;

create policy positions_select on public.positions for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());
create policy orders_select on public.orders for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());
