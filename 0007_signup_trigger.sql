-- =====================================================================
-- 0007  Automatic profile + demo funds when someone signs up
--
-- SECURITY NOTE: role and status are NEVER read from signup metadata.
-- Everyone starts as role 'user', status 'active'.
-- =====================================================================

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_ref      text := nullif(trim(coalesce(new.raw_user_meta_data ->> 'ref', '')), '');
  v_name     text := nullif(left(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), 120), '');
  v_referrer uuid;
begin
  if v_ref is not null then
    select id into v_referrer from public.profiles where referral_code = upper(v_ref);
  end if;

  insert into public.profiles (id, email, full_name, referred_by)
  values (new.id, new.email, v_name, v_referrer);

  if v_referrer is not null then
    insert into public.referrals (referrer_id, referred_id) values (v_referrer, new.id);
  end if;

  -- If granting demo funds ever fails, signup must still succeed.
  -- (The user can press "Reset demo account" to receive the funds.)
  begin
    perform public._grant_demo_balances(new.id);
  exception when others then
    raise warning 'Demo grant failed for user %: %', new.id, sqlerrm;
  end;

  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
