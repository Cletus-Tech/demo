-- =====================================================================
-- 0009  Grants and lockdown  (the single place that decides what the
--       browser is allowed to touch)
--
-- Supabase gives the "anon" and "authenticated" roles broad default
-- access. This file removes it all, then grants back ONLY what is needed.
-- If you add tables or functions in a later stage, repeat this pattern.
-- =====================================================================

-- 1. Remove everything -------------------------------------------------
revoke all on all tables    in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on all functions in schema public from public, anon, authenticated;

alter default privileges in schema public revoke all on tables    from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke all on functions from anon, authenticated;

-- 2. Read-only table access for signed-in users (rows are still filtered by RLS) --
grant select on
  public.profiles,
  public.platform_settings,
  public.assets,
  public.market_prices,
  public.wallets,
  public.ledger_entries,
  public.positions,
  public.orders,
  public.notifications,
  public.referrals,
  public.audit_logs
to authenticated;

-- 3. The only columns a user may edit directly -------------------------
grant update (full_name, phone, country, language) on public.profiles      to authenticated;
grant update (read_at)                             on public.notifications to authenticated;

-- 4. Functions the browser may call -----------------------------------
-- (used inside RLS policies, so they must be executable)
grant execute on function public.is_staff()      to authenticated;
grant execute on function public.is_admin()      to authenticated;
grant execute on function public.is_superadmin() to authenticated;

grant execute on function public.demo_refresh_prices()                       to authenticated;
grant execute on function public.place_spot_order(text, text, numeric)       to authenticated;
grant execute on function public.place_swap(text, text, numeric)             to authenticated;
grant execute on function public.open_leveraged_position(text, text, numeric, integer, numeric, numeric, integer)
                                                                             to authenticated;
grant execute on function public.close_position(uuid)                        to authenticated;
grant execute on function public.settle_my_positions()                       to authenticated;
grant execute on function public.demo_deposit(numeric)                       to authenticated;
grant execute on function public.demo_withdraw(numeric)                      to authenticated;
grant execute on function public.reset_demo_account()                        to authenticated;
grant execute on function public.admin_set_role(uuid, public.user_role)      to authenticated;
grant execute on function public.admin_set_status(uuid, public.account_status) to authenticated;

-- Not granted to anyone but the database owner:
--   _price, _post_ledger, _active_uid, _close_position, _grant_demo_balances, _audit, _notify,
--   handle_new_user, bootstrap_superadmin, v_ledger_integrity, and all table writes.

-- 5. Let the Supabase auth service fire the signup trigger -------------
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    execute 'grant execute on function public.handle_new_user() to supabase_auth_admin';
  end if;
end $$;
