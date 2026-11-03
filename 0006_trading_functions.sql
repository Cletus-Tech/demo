-- =====================================================================
-- 0006  Server-side DEMO trading functions
--
-- These are the ONLY way balances change. The browser calls them with
-- supabase.rpc(...). Each one:
--   * identifies the user from their login token (never from a parameter),
--   * refuses suspended accounts,
--   * validates every input,
--   * uses prices from public.market_prices (the browser cannot send a price),
--   * writes ledger entries (which update wallets through a trigger).
--
-- Everything here is DEMO: prices are simulated and no real money exists.
-- Functions starting with "_" are internal helpers; clients cannot call them.
-- =====================================================================

create or replace function public._fmt_usd(p numeric)
returns text language sql immutable as $$
  select case when p < 0 then '-$' else '$' end
         || to_char(abs(p), 'FM999,999,999,999,990.00')
$$;

-- The signed-in user's id, or an error if not signed in / suspended.
create or replace function public._active_uid()
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := (select auth.uid());
  v_status public.account_status;
begin
  if v_uid is null then
    raise exception 'Please sign in first' using errcode = '28000';
  end if;
  select status into v_status from public.profiles where id = v_uid;
  if v_status is null then
    raise exception 'Profile not found';
  end if;
  if v_status <> 'active' then
    raise exception 'This account is suspended';
  end if;
  return v_uid;
end $$;

create or replace function public._price(p_symbol text)
returns numeric language plpgsql security definer set search_path = public as $$
declare
  v_price  numeric;
  v_source text;
  v_at     timestamptz;
begin
  select mp.price, mp.source, mp.updated_at
    into v_price, v_source, v_at
    from public.market_prices mp
    join public.assets a on a.symbol = mp.symbol
   where mp.symbol = p_symbol and a.is_active;

  if v_price is null then
    raise exception 'No price available for %', p_symbol;
  end if;
  if v_source = 'live' and v_at < now() - interval '2 minutes' then
    raise exception 'The price for % is out of date, please try again shortly', p_symbol;
  end if;
  return v_price;
end $$;

create or replace function public._check_amount(p_amount numeric)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_amount is null or p_amount < 0.01 then
    raise exception 'Enter an amount of at least 0.01';
  end if;
  if p_amount > public._setting_num('max_order_usd', 10000000) then
    raise exception 'That amount is above the allowed maximum';
  end if;
end $$;

create or replace function public._check_tradable(p_symbol text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from public.assets
     where symbol = p_symbol and is_active and is_tradable and category <> 'fiat'
  ) then
    raise exception '% is not available for trading', coalesce(p_symbol, '(none)');
  end if;
end $$;

-- Single entry point for writing to the ledger.
create or replace function public._post_ledger(
  p_uid uuid, p_symbol text, p_amount numeric, p_type text, p_group uuid,
  p_ref_type text default null, p_ref_id uuid default null, p_memo text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.ledger_entries
    (user_id, symbol, amount, balance_after, entry_type, group_id, ref_type, ref_id, memo)
  values
    (p_uid, p_symbol, p_amount, 0, p_type, p_group, p_ref_type, p_ref_id, p_memo);
end $$;

-- ---------------------------------------------------------------------
-- Simulated prices. Any signed-in client may call this; it only moves
-- prices at most once per demo_price_interval_seconds, and only rows whose
-- source is 'demo'. Stage 2 replaces this with real market-data feeds.
-- ---------------------------------------------------------------------
create or replace function public.demo_refresh_prices()
returns void language plpgsql security definer set search_path = public as $$
declare
  v_vol numeric := public._setting_num('demo_volatility', 0.006);
  v_gap numeric := public._setting_num('demo_price_interval_seconds', 5);
begin
  if (select auth.uid()) is null then
    raise exception 'Please sign in first' using errcode = '28000';
  end if;

  update public.market_prices mp
     set price = greatest(
                   mp.demo_anchor * 0.2,
                   mp.price * (1 + (random()::numeric - 0.5) * v_vol)
                     + (mp.demo_anchor - mp.price) * 0.01),   -- gentle pull back to the anchor
         updated_at = now()
    from public.assets a
   where a.symbol = mp.symbol
     and a.category <> 'fiat'
     and mp.source = 'demo'
     and mp.updated_at < now() - make_interval(secs => v_gap::double precision);
end $$;

-- ---------------------------------------------------------------------
-- Demo starting funds (used at signup and on reset)
-- ---------------------------------------------------------------------
create or replace function public._grant_demo_balances(p_uid uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_cfg   jsonb;
  v_group uuid := gen_random_uuid();
  r       record;
  v_price numeric;
begin
  select value into v_cfg from public.platform_settings where key = 'demo_starting_balances_usd';
  if v_cfg is null then return; end if;

  for r in
    select e.key as sym, (e.value #>> '{}')::numeric as usd
      from jsonb_each(v_cfg) e
  loop
    continue when r.usd is null or r.usd <= 0;
    continue when not exists (select 1 from public.assets where symbol = r.sym and is_active);
    v_price := public._price(r.sym);
    perform public._post_ledger(p_uid, r.sym, round(r.usd / v_price, 10), 'demo_grant', v_group,
                                null, null, 'Demo starting balance');
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Spot buy / sell at the current market price. Amount is in USD.
-- ---------------------------------------------------------------------
create or replace function public.place_spot_order(p_symbol text, p_side text, p_amount_usd numeric)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := public._active_uid();
  v_sym   text := upper(coalesce(p_symbol, ''));
  v_amt   numeric := round(p_amount_usd, 2);
  v_price numeric;
  v_qty   numeric;
  v_bal   numeric;
  v_group uuid := gen_random_uuid();
  v_order uuid := gen_random_uuid();
begin
  if p_side is null or p_side not in ('buy', 'sell') then
    raise exception 'Side must be buy or sell';
  end if;
  perform public._check_amount(v_amt);
  perform public._check_tradable(v_sym);

  v_price := public._price(v_sym);
  v_qty   := round(v_amt / v_price, 10);
  if v_qty <= 0 then raise exception 'That amount is too small'; end if;

  if p_side = 'buy' then
    select balance into v_bal from public.wallets
     where user_id = v_uid and symbol = 'USD' for update;
    if coalesce(v_bal, 0) < v_amt then
      raise exception 'Not enough USD in your demo balance';
    end if;
    perform public._post_ledger(v_uid, 'USD', -v_amt, 'spot_buy', v_group, 'order', v_order);
    perform public._post_ledger(v_uid, v_sym,  v_qty, 'spot_buy', v_group, 'order', v_order);
  else
    select balance into v_bal from public.wallets
     where user_id = v_uid and symbol = v_sym for update;
    if coalesce(v_bal, 0) < v_qty then
      raise exception 'Not enough % in your demo balance', v_sym;
    end if;
    perform public._post_ledger(v_uid, v_sym, -v_qty, 'spot_sell', v_group, 'order', v_order);
    perform public._post_ledger(v_uid, 'USD',  v_amt, 'spot_sell', v_group, 'order', v_order);
  end if;

  insert into public.orders (id, user_id, kind, side, symbol, amount_usd, price, quantity, group_id)
  values (v_order, v_uid, 'spot', p_side, v_sym, v_amt, v_price, v_qty, v_group);

  perform public._notify(v_uid,
    case when p_side = 'buy' then 'Bought ' else 'Sold ' end
      || public._fmt_usd(v_amt) || ' of ' || v_sym, 'trade');
  return v_order;
end $$;

-- ---------------------------------------------------------------------
-- Convert (swap) between two assets. Amount is in USD value.
-- ---------------------------------------------------------------------
create or replace function public.place_swap(p_from text, p_to text, p_amount_usd numeric)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := public._active_uid();
  v_from  text := upper(coalesce(p_from, ''));
  v_to    text := upper(coalesce(p_to, ''));
  v_amt   numeric := round(p_amount_usd, 2);
  v_pf    numeric;
  v_pt    numeric;
  v_qf    numeric;
  v_qt    numeric;
  v_bal   numeric;
  v_group uuid := gen_random_uuid();
  v_order uuid := gen_random_uuid();
begin
  if v_from = v_to then raise exception 'Pick two different assets'; end if;
  perform public._check_amount(v_amt);
  if not exists (select 1 from public.assets where symbol = v_from and is_active)
     or not exists (select 1 from public.assets where symbol = v_to and is_active) then
    raise exception 'One of those assets is not available';
  end if;

  v_pf := public._price(v_from);
  v_pt := public._price(v_to);
  v_qf := round(v_amt / v_pf, 10);
  v_qt := round(v_amt / v_pt, 10);
  if v_qf <= 0 or v_qt <= 0 then raise exception 'That amount is too small'; end if;

  select balance into v_bal from public.wallets
   where user_id = v_uid and symbol = v_from for update;
  if coalesce(v_bal, 0) < v_qf then
    raise exception 'Not enough % in your demo balance', v_from;
  end if;

  perform public._post_ledger(v_uid, v_from, -v_qf, 'swap_out', v_group, 'order', v_order);
  perform public._post_ledger(v_uid, v_to,    v_qt, 'swap_in',  v_group, 'order', v_order);

  insert into public.orders (id, user_id, kind, side, symbol, from_symbol, amount_usd, price, quantity, group_id)
  values (v_order, v_uid, 'swap', 'convert', v_to, v_from, v_amt, v_pt, v_qt, v_group);

  perform public._notify(v_uid,
    'Converted ' || public._fmt_usd(v_amt) || ' from ' || v_from || ' to ' || v_to, 'trade');
  return v_order;
end $$;

-- ---------------------------------------------------------------------
-- Leveraged position (demo). Margin is taken from USD.
-- ---------------------------------------------------------------------
create or replace function public.open_leveraged_position(
  p_symbol text, p_side text, p_margin_usd numeric, p_leverage integer,
  p_take_profit numeric, p_stop_loss numeric, p_duration_sec integer)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := public._active_uid();
  v_sym    text := upper(coalesce(p_symbol, ''));
  v_margin numeric := round(p_margin_usd, 2);
  v_tp     numeric := nullif(p_take_profit, 0);
  v_sl     numeric := nullif(p_stop_loss, 0);
  v_dur    integer := nullif(p_duration_sec, 0);
  v_price  numeric;
  v_bal    numeric;
  v_pos    uuid := gen_random_uuid();
  v_group  uuid := gen_random_uuid();
begin
  if p_side is null or p_side not in ('long', 'short') then
    raise exception 'Side must be long or short';
  end if;
  perform public._check_amount(v_margin);
  perform public._check_tradable(v_sym);
  if p_leverage is null or p_leverage < 2
     or p_leverage > public._setting_num('max_leverage', 100) then
    raise exception 'Leverage must be between 2x and %x', public._setting_num('max_leverage', 100)::int;
  end if;
  if v_dur is not null and (v_dur < 10 or v_dur > 2592000) then
    raise exception 'Duration must be between 10 seconds and 30 days';
  end if;

  v_price := public._price(v_sym);

  if p_side = 'long' then
    if v_tp is not null and v_tp <= v_price then raise exception 'Take profit must be above the current price for a long trade'; end if;
    if v_sl is not null and v_sl >= v_price then raise exception 'Stop loss must be below the current price for a long trade'; end if;
  else
    if v_tp is not null and v_tp >= v_price then raise exception 'Take profit must be below the current price for a short trade'; end if;
    if v_sl is not null and v_sl <= v_price then raise exception 'Stop loss must be above the current price for a short trade'; end if;
  end if;

  select balance into v_bal from public.wallets
   where user_id = v_uid and symbol = 'USD' for update;
  if coalesce(v_bal, 0) < v_margin then
    raise exception 'Not enough USD in your demo balance';
  end if;

  perform public._post_ledger(v_uid, 'USD', -v_margin, 'position_open', v_group, 'position', v_pos);

  insert into public.positions
    (id, user_id, symbol, side, margin_usd, leverage, entry_price, take_profit, stop_loss, expires_at)
  values
    (v_pos, v_uid, v_sym, p_side, v_margin, p_leverage, v_price, v_tp, v_sl,
     case when v_dur is null then null else now() + make_interval(secs => v_dur) end);

  insert into public.orders
    (user_id, kind, side, symbol, amount_usd, price, quantity, leverage, position_id, group_id)
  values
    (v_uid, 'leveraged', case when p_side = 'long' then 'buy' else 'sell' end, v_sym,
     v_margin, v_price, round(v_margin * p_leverage / v_price, 10), p_leverage, v_pos, v_group);

  perform public._notify(v_uid, 'Opened ' || p_leverage || 'x ' || p_side || ' on ' || v_sym, 'trade');
  return v_pos;
end $$;

-- Internal: close one open position at the current price.
create or replace function public._close_position(p_id uuid, p_reason text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  p        public.positions;
  v_price  numeric;
  v_pnl    numeric;
  v_payout numeric;
  v_group  uuid := gen_random_uuid();
begin
  select * into p from public.positions where id = p_id and status = 'open' for update;
  if not found then
    raise exception 'Position not found or already closed';
  end if;

  v_price  := public._price(p.symbol);
  v_pnl    := p.margin_usd * p.leverage
              * (case when p.side = 'long' then 1 else -1 end)
              * (v_price / p.entry_price - 1);
  v_payout := greatest(0, round(p.margin_usd + v_pnl, 10));

  if v_payout > 0 then
    perform public._post_ledger(p.user_id, 'USD', v_payout, 'position_close', v_group, 'position', p.id);
  end if;

  update public.positions
     set status = 'closed', close_price = v_price, close_reason = p_reason,
         payout_usd = v_payout, pnl_usd = v_payout - p.margin_usd, closed_at = now()
   where id = p.id;

  perform public._notify(p.user_id,
    p.symbol || ' ' || p.side || ' closed (' || replace(p_reason, '_', ' ') || '): '
      || public._fmt_usd(v_payout - p.margin_usd), 'trade');

  return jsonb_build_object(
    'id', p.id, 'symbol', p.symbol, 'side', p.side, 'reason', p_reason,
    'pnl', round(v_payout - p.margin_usd, 2));
end $$;

create or replace function public.close_position(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := public._active_uid();
begin
  if not exists (select 1 from public.positions where id = p_id and user_id = v_uid and status = 'open') then
    raise exception 'Position not found or already closed';
  end if;
  return public._close_position(p_id, 'manual');
end $$;

-- Closes the caller's positions that hit take-profit, stop-loss,
-- liquidation or their time limit. The browser calls this on every price poll.
create or replace function public.settle_my_positions()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := public._active_uid();
  r        record;
  v_price  numeric;
  v_pnl    numeric;
  v_reason text;
  v_out    jsonb := '[]'::jsonb;
begin
  for r in
    select * from public.positions
     where user_id = v_uid and status = 'open'
     order by opened_at
  loop
    v_price := public._price(r.symbol);
    v_pnl   := r.margin_usd * r.leverage
               * (case when r.side = 'long' then 1 else -1 end)
               * (v_price / r.entry_price - 1);
    v_reason := null;

    if r.expires_at is not null and now() >= r.expires_at then
      v_reason := 'duration_ended';
    elsif v_pnl <= -r.margin_usd then
      v_reason := 'liquidated';
    elsif r.take_profit is not null
          and ((r.side = 'long'  and v_price >= r.take_profit)
            or (r.side = 'short' and v_price <= r.take_profit)) then
      v_reason := 'take_profit';
    elsif r.stop_loss is not null
          and ((r.side = 'long'  and v_price <= r.stop_loss)
            or (r.side = 'short' and v_price >= r.stop_loss)) then
      v_reason := 'stop_loss';
    end if;

    if v_reason is not null then
      v_out := v_out || jsonb_build_array(public._close_position(r.id, v_reason));
    end if;
  end loop;
  return v_out;
end $$;

-- ---------------------------------------------------------------------
-- Demo deposit / withdraw. NO real payment is involved. Limits come from
-- platform_settings so one user cannot mint unlimited demo money.
-- ---------------------------------------------------------------------
create or replace function public.demo_deposit(p_amount numeric)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := public._active_uid();
  v_amt numeric := round(p_amount, 2);
  v_bal numeric;
begin
  if v_amt is null or v_amt < 0.01 then
    raise exception 'Enter an amount of at least 0.01';
  end if;
  if v_amt > public._setting_num('demo_max_topup_usd', 100000) then
    raise exception 'Demo deposits are limited to % per request',
      public._fmt_usd(public._setting_num('demo_max_topup_usd', 100000));
  end if;

  select balance into v_bal from public.wallets
   where user_id = v_uid and symbol = 'USD' for update;
  if coalesce(v_bal, 0) + v_amt > public._setting_num('demo_max_usd_balance', 1000000) then
    raise exception 'This would exceed the demo balance limit';
  end if;

  perform public._post_ledger(v_uid, 'USD', v_amt, 'demo_deposit', gen_random_uuid(),
                              null, null, 'Demo funds - no real payment');
  perform public._notify(v_uid, 'Demo deposit of ' || public._fmt_usd(v_amt), 'wallet');
end $$;

create or replace function public.demo_withdraw(p_amount numeric)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := public._active_uid();
  v_amt numeric := round(p_amount, 2);
  v_bal numeric;
begin
  if v_amt is null or v_amt < 0.01 then
    raise exception 'Enter an amount of at least 0.01';
  end if;

  select balance into v_bal from public.wallets
   where user_id = v_uid and symbol = 'USD' for update;
  if coalesce(v_bal, 0) < v_amt then
    raise exception 'Not enough USD in your demo balance';
  end if;

  perform public._post_ledger(v_uid, 'USD', -v_amt, 'demo_withdrawal', gen_random_uuid(),
                              null, null, 'Demo funds - no real payout');
  perform public._notify(v_uid, 'Demo withdrawal of ' || public._fmt_usd(v_amt), 'wallet');
end $$;

-- Closes open trades, zeroes every wallet with offsetting ledger entries,
-- then grants the starting demo balances again. History is kept.
create or replace function public.reset_demo_account()
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := public._active_uid();
  r       record;
  v_group uuid := gen_random_uuid();
begin
  for r in select id from public.positions where user_id = v_uid and status = 'open' loop
    perform public._close_position(r.id, 'manual');
  end loop;

  for r in
    select symbol, balance from public.wallets
     where user_id = v_uid and balance > 0
     for update
  loop
    perform public._post_ledger(v_uid, r.symbol, -r.balance, 'demo_reset', v_group,
                                null, null, 'Demo account reset');
  end loop;

  perform public._grant_demo_balances(v_uid);
  perform public._audit('demo_account_reset', 'profile', v_uid::text, '{}'::jsonb);
  perform public._notify(v_uid, 'Demo account reset', 'wallet');
end $$;
