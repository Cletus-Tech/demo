create or replace function private.redeem_classroom_access_pin(p_pin text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_uid uuid; v_hash text; v_id uuid;
begin
  v_uid := auth.uid();
  if v_uid is null or length(btrim(coalesce(p_pin,''))) <> 10 then return false; end if;
  if not exists (
    select 1 from public.profiles p join public.students s on s.user_id=p.id
    where p.id=v_uid and p.account_type='student' and s.status='active'
  ) then return false; end if;
  v_hash := encode(extensions.digest(convert_to(upper(btrim(p_pin)),'UTF8'),'sha256'),'hex');
  select id into v_id
  from public.classroom_access_passes
  where user_id=v_uid and pin_hash=v_hash and redeemed_at is null
    and revoked_at is null and failed_attempts < 5
  order by issued_at desc limit 1 for update;
  if found then
    update public.classroom_access_passes set redeemed_at=now() where id=v_id and redeemed_at is null;
    return found;
  end if;
  select id into v_id from public.classroom_access_passes
  where user_id=v_uid and redeemed_at is null and revoked_at is null and failed_attempts < 5
  order by issued_at desc limit 1 for update;
  if found then update public.classroom_access_passes set failed_attempts=failed_attempts+1 where id=v_id; end if;
  return false;
end;
$$;