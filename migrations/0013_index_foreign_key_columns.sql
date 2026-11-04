-- 0013_index_foreign_key_columns.sql
-- Add covering indexes for foreign keys flagged by the database performance advisor.
create index if not exists ledger_entries_symbol_fk_idx on public.ledger_entries(symbol);
create index if not exists orders_from_symbol_fk_idx on public.orders(from_symbol);
create index if not exists orders_position_id_fk_idx on public.orders(position_id);
create index if not exists orders_symbol_fk_idx on public.orders(symbol);
create index if not exists positions_symbol_fk_idx on public.positions(symbol);
create index if not exists profiles_referred_by_fk_idx on public.profiles(referred_by);
create index if not exists referrals_referrer_id_fk_idx on public.referrals(referrer_id);
create index if not exists wallets_symbol_fk_idx on public.wallets(symbol);
