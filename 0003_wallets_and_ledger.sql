-- =====================================================================
-- 0003  Wallets and the append-only ledger
--
-- Rules enforced by the database itself:
--   * A wallet balance changes ONLY when a ledger entry is inserted.
--   * Ledger entries can never be updated or deleted.
--   * Balances can never go below zero.
--   * Clients (browsers) get no write access to either table.
-- =====================================================================

create table public.wallets (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  symbol     text not null references public.assets (symbol),
  balance    numeric(28,10) not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, symbol)
);

create table public.ledger_entries (
  id            bigint generated always as identity primary key,
  user_id       uuid not null references public.profiles (id) on delete restrict,
  symbol        text not null references public.assets (symbol),
  amount        numeric(28,10) not null check (amount <> 0),   -- + credit, - debit
  balance_after numeric(28,10) not null check (balance_after >= 0),
  entry_type    text not null check (entry_type in (
                  'demo_grant','demo_deposit','demo_withdrawal','demo_reset',
                  'spot_buy','spot_sell','swap_out','swap_in',
                  'position_open','position_close')),
  group_id      uuid not null default gen_random_uuid(),       -- ties together the legs of one action
  ref_type      text,
  ref_id        uuid,
  memo          text,
  -- Real-money entries are impossible until a future migration deliberately removes this check.
  mode          text not null default 'demo' check (mode = 'demo'),
  created_at    timestamptz not null default now()
);
create index ledger_entries_user_idx  on public.ledger_entries (user_id, created_at desc);
create index ledger_entries_group_idx on public.ledger_entries (group_id);

-- Inserting a ledger entry updates the wallet and stamps balance_after.
create or replace function public._ledger_apply()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_new numeric;
begin
  insert into public.wallets (user_id, symbol, balance)
  values (new.user_id, new.symbol, 0)
  on conflict (user_id, symbol) do nothing;

  update public.wallets
     set balance = balance + new.amount, updated_at = now()
   where user_id = new.user_id and symbol = new.symbol
   returning balance into v_new;      -- row lock serialises concurrent changes; CHECK blocks < 0

  new.balance_after := v_new;
  return new;
end $$;

create trigger ledger_apply
  before insert on public.ledger_entries
  for each row execute function public._ledger_apply();

-- Ledger rows are permanent.
create or replace function public._block_modification()
returns trigger language plpgsql as $$
begin
  raise exception '% on % is not allowed: this table is append-only', tg_op, tg_table_name;
end $$;

create trigger ledger_no_update_delete
  before update or delete on public.ledger_entries
  for each row execute function public._block_modification();
create trigger ledger_no_truncate
  before truncate on public.ledger_entries
  for each statement execute function public._block_modification();

-- Wallets may only be touched from inside the ledger trigger (trigger depth >= 2).
-- Even a manual UPDATE in the SQL editor is refused.
create or replace function public._wallet_guard()
returns trigger language plpgsql as $$
begin
  if pg_trigger_depth() < 2 then
    raise exception 'Wallet balances can only change through ledger entries';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;

create trigger wallet_guard
  before insert or update or delete on public.wallets
  for each row execute function public._wallet_guard();

-- Integrity check: should ALWAYS return zero rows.
--   select * from public.v_ledger_integrity;
create or replace view public.v_ledger_integrity as
select coalesce(w.user_id, l.user_id) as user_id,
       coalesce(w.symbol,  l.symbol)  as symbol,
       coalesce(w.balance, 0)         as wallet_balance,
       coalesce(l.total,   0)         as ledger_total
  from public.wallets w
  full outer join (
         select user_id, symbol, sum(amount) as total
           from public.ledger_entries
          group by user_id, symbol
       ) l on l.user_id = w.user_id and l.symbol = w.symbol
 where coalesce(w.balance, 0) <> coalesce(l.total, 0);

alter table public.wallets        enable row level security;
alter table public.ledger_entries enable row level security;

create policy wallets_select on public.wallets for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());
create policy ledger_select on public.ledger_entries for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());
