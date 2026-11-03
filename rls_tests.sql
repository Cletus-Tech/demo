-- =====================================================================
-- RLS / SECURITY TEST SCRIPT
--
-- HOW TO RUN: Supabase dashboard > SQL Editor > New query > paste this
-- whole file > Run.   (Run it AFTER setup_all.sql.)
--
-- WHAT YOU WILL SEE: a red ERROR box. THAT IS NORMAL AND INTENTIONAL.
-- The script creates two fake users, tests them, and then raises an error
-- so that every fake row is rolled back and nothing is left in your database.
-- Read the message: it starts with "ALL TESTS PASSED" or "SOME TESTS FAILED"
-- and lists every check as PASS or FAIL.
--
-- If you see a different error (for example about auth.users), copy the
-- full text and send it to me.
-- =====================================================================

do $test$
declare
  a uuid := '00000000-0000-4000-8000-0000000000a1';
  b uuid := '00000000-0000-4000-8000-0000000000b2';
  cases   text[][];
  i       int;
  c_name  text; c_who text; c_sql text; c_kind text; c_expect text;
  q       text;
  v       text;
  err     text;
  apos    text;
  passed  int := 0;
  failed  int := 0;
  report  text := '';
begin
  -- Two throw-away users. The signup trigger gives each a profile and demo funds.
  insert into auth.users (id, aud, role, email, raw_user_meta_data)
  values (a, 'authenticated', 'authenticated', 'rls-test-a@example.invalid', '{"full_name":"RLS Test A"}'),
         (b, 'authenticated', 'authenticated', 'rls-test-b@example.invalid', '{"full_name":"RLS Test B"}');

  -- name | who (anon, A, B, db) | sql returning ONE value | kind (error, eq, ok) | expected value
  cases := array[
    -- ---------- anonymous visitors see nothing ----------
    array['anon cannot read profiles','anon',
          $q$select count(*)::text from public.profiles$q$,'error',''],
    array['anon cannot read market prices','anon',
          $q$select count(*)::text from public.market_prices$q$,'error',''],
    array['anon cannot place an order','anon',
          $q$select public.place_spot_order('BTC','buy',10)::text$q$,'error',''],
    array['anon cannot refresh prices','anon',
          $q$select public.demo_refresh_prices()::text$q$,'error',''],

    -- ---------- a normal user can read only their own data ----------
    array['user sees only their own profile','A',
          $q$select count(*)::text from public.profiles$q$,'eq','1'],
    array['user has 5 demo wallets after signup','A',
          $q$select count(*)::text from public.wallets$q$,'eq','5'],
    array['user cannot see another user wallets','A',
          $q$select count(*)::text from public.wallets where user_id = '{B}'$q$,'eq','0'],
    array['user cannot see another user ledger','A',
          $q$select count(*)::text from public.ledger_entries where user_id = '{B}'$q$,'eq','0'],
    array['user cannot read the audit log','A',
          $q$select count(*)::text from public.audit_logs$q$,'eq','0'],

    -- ---------- a normal user cannot write money tables ----------
    array['user cannot edit a wallet balance','A',
          $q$with u as (update public.wallets set balance = 999999999 where user_id = '{A}' returning 1) select count(*)::text from u$q$,'error',''],
    array['user cannot insert a ledger entry','A',
          $q$with i as (insert into public.ledger_entries (user_id, symbol, amount, entry_type) values ('{A}','USD',1000000,'demo_deposit') returning 1) select count(*)::text from i$q$,'error',''],
    array['user cannot delete ledger entries','A',
          $q$with d as (delete from public.ledger_entries where user_id = '{A}' returning 1) select count(*)::text from d$q$,'error',''],
    array['user cannot create a position directly','A',
          $q$with i as (insert into public.positions (user_id, symbol, side, margin_usd, leverage, entry_price) values ('{A}','BTC','long',1,2,1) returning 1) select count(*)::text from i$q$,'error',''],
    array['user cannot create an order directly','A',
          $q$with i as (insert into public.orders (user_id, kind, side, symbol, amount_usd, price, quantity) values ('{A}','spot','buy','BTC',1,1,1) returning 1) select count(*)::text from i$q$,'error',''],
    array['user cannot change market prices','A',
          $q$with u as (update public.market_prices set price = 1 where symbol = 'BTC' returning 1) select count(*)::text from u$q$,'error',''],

    -- ---------- profile protection ----------
    array['user cannot make themselves superadmin','A',
          $q$with u as (update public.profiles set role = 'superadmin' where id = '{A}' returning 1) select count(*)::text from u$q$,'error',''],
    array['user cannot change their own status','A',
          $q$with u as (update public.profiles set status = 'active' where id = '{A}' returning 1) select count(*)::text from u$q$,'error',''],
    array['user can edit their own name','A',
          $q$with u as (update public.profiles set full_name = 'RLS Test A2' where id = '{A}' returning 1) select count(*)::text from u$q$,'eq','1'],
    array['user cannot edit another user name','A',
          $q$with u as (update public.profiles set full_name = 'hacked' where id = '{B}' returning 1) select count(*)::text from u$q$,'eq','0'],

    -- ---------- internal functions are not callable ----------
    array['user cannot call admin_set_role','A',
          $q$select public.admin_set_role('{B}', 'admin')::text$q$,'error',''],
    array['user cannot call internal ledger helper','A',
          $q$select public._post_ledger('{A}','USD',1000000,'demo_deposit',gen_random_uuid())::text$q$,'error',''],
    array['user cannot call internal grant helper','A',
          $q$select public._grant_demo_balances('{A}')::text$q$,'error',''],
    array['user cannot call bootstrap_superadmin','A',
          $q$select public.bootstrap_superadmin('rls-test-a@example.invalid')::text$q$,'error',''],

    -- ---------- trading works and is validated ----------
    array['spot buy works','A',
          $q$select 'ok' from (select public.place_spot_order('BTC','buy',100)) s$q$,'eq','ok'],
    array['USD is debited after the buy','A',
          $q$select round(balance,2)::text from public.wallets where user_id = '{A}' and symbol = 'USD'$q$,'eq','2900.00'],
    array['cannot buy more than the USD balance','A',
          $q$select public.place_spot_order('BTC','buy',1000000)::text$q$,'error',''],
    array['zero amount rejected','A',
          $q$select public.place_spot_order('BTC','buy',0)::text$q$,'error',''],
    array['negative amount rejected','A',
          $q$select public.place_spot_order('BTC','buy',-5)::text$q$,'error',''],
    array['cannot sell more than owned','A',
          $q$select public.place_spot_order('SOL','sell',999999)::text$q$,'error',''],
    array['cannot spot-trade fiat','A',
          $q$select public.place_spot_order('USD','buy',10)::text$q$,'error',''],
    array['unknown asset rejected','A',
          $q$select public.place_spot_order('FAKE','buy',10)::text$q$,'error',''],
    array['swap works','A',
          $q$select 'ok' from (select public.place_swap('USD','ETH',50)) s$q$,'eq','ok'],
    array['swap between the same asset rejected','A',
          $q$select public.place_swap('BTC','BTC',10)::text$q$,'error',''],
    array['leveraged position opens','A',
          $q$select 'ok' from (select public.open_leveraged_position('AAPL','long',100,10,0,0,0)) s$q$,'eq','ok'],
    array['USD reflects spot, swap and margin','A',
          $q$select round(balance,2)::text from public.wallets where user_id = '{A}' and symbol = 'USD'$q$,'eq','2750.00'],
    array['leverage above the maximum rejected','A',
          $q$select public.open_leveraged_position('AAPL','long',10,5000,0,0,0)::text$q$,'error',''],
    array['impossible take-profit rejected','A',
          $q$select public.open_leveraged_position('AAPL','long',10,5,1,0,0)::text$q$,'error',''],
    array['another user cannot close my position','B',
          $q$select public.close_position('{APOS}'::uuid)::text$q$,'error',''],
    array['owner can close their position','A',
          $q$select public.close_position('{APOS}'::uuid) ->> 'reason'$q$,'eq','manual'],
    array['position is now closed','A',
          $q$select status from public.positions where id = '{APOS}'::uuid$q$,'eq','closed'],
    array['closing twice is rejected','A',
          $q$select public.close_position('{APOS}'::uuid)::text$q$,'error',''],

    -- ---------- demo deposit / withdraw limits ----------
    array['demo deposit within limit works','A',
          $q$select 'ok' from (select public.demo_deposit(100)) s$q$,'eq','ok'],
    array['demo deposit above limit rejected','A',
          $q$select public.demo_deposit(1000000000)::text$q$,'error',''],
    array['withdraw more than balance rejected','A',
          $q$select public.demo_withdraw(1000000000)::text$q$,'error',''],

    -- ---------- reset ----------
    array['B reset demo account works','B',
          $q$select 'ok' from (select public.reset_demo_account()) s$q$,'eq','ok'],
    array['B USD back to starting amount','B',
          $q$select round(balance,2)::text from public.wallets where user_id = '{B}' and symbol = 'USD'$q$,'eq','3000.00'],

    -- ---------- database-level protections (even for the owner) ----------
    array['ledger and wallets agree (integrity view empty)','db',
          $q$select count(*)::text from public.v_ledger_integrity$q$,'eq','0'],
    array['direct wallet update is refused','db',
          $q$with u as (update public.wallets set balance = 5 where user_id = '{A}' returning 1) select count(*)::text from u$q$,'error',''],
    array['ledger update is refused','db',
          $q$with u as (update public.ledger_entries set memo = 'x' where user_id = '{A}' returning 1) select count(*)::text from u$q$,'error',''],
    array['ledger delete is refused','db',
          $q$with d as (delete from public.ledger_entries where user_id = '{A}' returning 1) select count(*)::text from d$q$,'error',''],
    array['audit log update is refused','db',
          $q$with u as (update public.audit_logs set action = 'x' returning 1) select count(*)::text from u$q$,'error',''],

    -- ---------- suspension ----------
    array['suspend B (done as database owner)','db',
          $q$with u as (update public.profiles set status = 'suspended' where id = '{B}' returning 1) select count(*)::text from u$q$,'eq','1'],
    array['suspended user cannot trade','B',
          $q$select public.place_spot_order('BTC','buy',10)::text$q$,'error',''],
    array['suspension was written to the audit log','db',
          $q$select count(*)::text from public.audit_logs where action = 'status_changed' and target_id = '{B}'$q$,'eq','1'],

    -- ---------- roles ----------
    array['promote A to admin (as database owner)','db',
          $q$with u as (update public.profiles set role = 'admin' where id = '{A}' returning 1) select count(*)::text from u$q$,'eq','1'],
    array['admin can see both test profiles','A',
          $q$select count(*)::text from public.profiles where id in ('{A}','{B}')$q$,'eq','2'],
    array['admin can read other user wallets','A',
          $q$select count(*)::text from public.wallets where user_id = '{B}'$q$,'eq','5'],
    array['admin can read the audit log','A',
          $q$select (count(*) > 0)::text from public.audit_logs$q$,'eq','true'],
    array['admin cannot change roles','A',
          $q$select public.admin_set_role('{B}', 'support')::text$q$,'error',''],
    array['admin can reactivate a suspended user','A',
          $q$select 'ok' from (select public.admin_set_status('{B}', 'active')) s$q$,'eq','ok'],
    array['admin cannot suspend themselves','A',
          $q$select public.admin_set_status('{A}', 'suspended')::text$q$,'error',''],
    array['promote A to superadmin (as database owner)','db',
          $q$with u as (update public.profiles set role = 'superadmin' where id = '{A}' returning 1) select count(*)::text from u$q$,'eq','1'],
    array['superadmin can change another user role','A',
          $q$select 'ok' from (select public.admin_set_role('{B}', 'support')) s$q$,'eq','ok'],
    array['superadmin cannot change their own role','A',
          $q$select public.admin_set_role('{A}', 'user')::text$q$,'error',''],
    array['role change was written to the audit log','db',
          $q$select count(*)::text from public.audit_logs where action = 'role_changed' and target_id = '{B}'$q$,'eq','1']
  ];

  for i in 1 .. array_length(cases, 1) loop
    c_name := cases[i][1]; c_who := cases[i][2]; c_sql := cases[i][3];
    c_kind := cases[i][4]; c_expect := cases[i][5];

    -- Work out the first position id of user A (as the database owner).
    execute 'reset role';
    perform set_config('request.jwt.claims', '', true);
    select p.id::text into apos from public.positions p where p.user_id = a order by p.opened_at limit 1;

    q := replace(replace(replace(c_sql, '{A}', a::text), '{B}', b::text), '{APOS}', coalesce(apos, '00000000-0000-4000-8000-000000000000'));

    -- Become the requested user.
    if c_who = 'anon' then
      perform set_config('request.jwt.claims', '{"role":"anon"}', true);
      execute 'set local role anon';
    elsif c_who = 'A' or c_who = 'B' then
      perform set_config('request.jwt.claims',
        json_build_object('sub', case when c_who = 'A' then a else b end, 'role', 'authenticated')::text, true);
      execute 'set local role authenticated';
    end if;

    v := null; err := null;
    begin
      execute q into v;
    exception when others then
      err := sqlerrm;
    end;

    execute 'reset role';
    perform set_config('request.jwt.claims', '', true);

    if (c_kind = 'error' and err is not null)
       or (c_kind = 'ok' and err is null)
       or (c_kind = 'eq' and err is null and v = c_expect) then
      passed := passed + 1;
      report := report || E'\nPASS  ' || c_name;
    else
      failed := failed + 1;
      report := report || E'\nFAIL  ' || c_name
                || ' (expected ' || c_kind || coalesce(' ' || nullif(c_expect, ''), '')
                || '; got ' || coalesce('value ' || v, 'no value') || coalesce(', error: ' || err, '') || ')';
    end if;
  end loop;

  raise exception E'%\n%',
    case when failed = 0
         then 'ALL TESTS PASSED (' || passed || ' passed, 0 failed). This error is intentional: it rolls back the test users.'
         else 'SOME TESTS FAILED (' || passed || ' passed, ' || failed || ' failed). Details below. Test users were rolled back.'
    end,
    report;
end
$test$;
