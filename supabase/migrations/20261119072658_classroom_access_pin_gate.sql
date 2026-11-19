create table if not exists public.classroom_access_passes (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.learning_access_requests(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  programme_id uuid not null references public.learning_programmes(id) on delete cascade,
  pin_hash text not null,
  failed_attempts integer not null default 0 check (failed_attempts between 0 and 5),
  issued_by uuid references auth.users(id),
  issued_at timestamptz not null default now(),
  redeemed_at timestamptz,
  revoked_at timestamptz
);
alter table public.classroom_access_passes enable row level security;
revoke all on public.classroom_access_passes from anon, authenticated;
comment on table public.classroom_access_passes is 'Hashed one-time classroom entry PINs. Plaintext PINs are returned only at issuance and never stored.';

create or replace function private.issue_classroom_access_pin(p_request_id uuid)
returns text language plpgsql security definer set search_path = ''
as $$
declare v_user_id uuid; v_programme_id uuid; v_pin text;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  if not (private.has_permission('finance.manage') or private.has_permission('students.manage')) then
    raise exception 'You are not authorised to issue classroom passes';
  end if;
  select user_id, programme_id into v_user_id, v_programme_id
  from public.learning_access_requests where id=p_request_id and status='approved';
  if not found then raise exception 'Only an approved learning request can receive a classroom pass'; end if;
  v_pin := upper(encode(extensions.gen_random_bytes(5), 'hex'));
  insert into public.classroom_access_passes(request_id,user_id,programme_id,pin_hash,issued_by,issued_at,failed_attempts,redeemed_at,revoked_at)
  values (p_request_id,v_user_id,v_programme_id,encode(extensions.digest(convert_to(v_pin,'UTF8'),'sha256'),'hex'),auth.uid(),now(),0,null,null)
  on conflict (request_id) do update set pin_hash=excluded.pin_hash,issued_by=excluded.issued_by,issued_at=now(),failed_attempts=0,redeemed_at=null,revoked_at=null;
  insert into public.notifications(user_id,title,body)
  values (v_user_id,'Your classroom pass is ready','Your learning payment has been approved. Ask the centre administrator for your unique classroom PIN to unlock your learning programme.');
  return v_pin;
end;
$$;

create or replace function private.redeem_classroom_access_pin(p_pin text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_uid uuid; v_hash text; v_id uuid; v_pass_hash text;
begin
  v_uid := auth.uid();
  if v_uid is null or length(btrim(coalesce(p_pin,''))) <> 10 then return false; end if;
  if not exists (select 1 from public.profiles p join public.students s on s.user_id=p.id where p.id=v_uid and p.account_type='student' and s.status='active') then return false; end if;
  v_hash := encode(extensions.digest(convert_to(upper(btrim(p_pin)),'UTF8'),'sha256'),'hex');
  select id,pin_hash into v_id,v_pass_hash from public.classroom_access_passes
  where user_id=v_uid and redeemed_at is null and revoked_at is null and failed_attempts < 5
  order by issued_at desc limit 1;
  if not found then return false; end if;
  if v_pass_hash <> v_hash then
    update public.classroom_access_passes set failed_attempts=failed_attempts+1 where id=v_id;
    return false;
  end if;
  update public.classroom_access_passes set redeemed_at=now() where id=v_id;
  return true;
end;
$$;

create or replace function public.issue_classroom_access_pin(p_request_id uuid)
returns text language sql security definer set search_path = ''
as $$ select private.issue_classroom_access_pin(p_request_id); $$;
create or replace function public.redeem_classroom_access_pin(p_pin text)
returns boolean language sql security definer set search_path = ''
as $$ select private.redeem_classroom_access_pin(p_pin); $$;
revoke all on function private.issue_classroom_access_pin(uuid) from public,anon,authenticated;
revoke all on function private.redeem_classroom_access_pin(text) from public,anon,authenticated;
revoke all on function public.issue_classroom_access_pin(uuid) from public,anon;
revoke all on function public.redeem_classroom_access_pin(text) from public,anon;
grant execute on function public.issue_classroom_access_pin(uuid) to authenticated;
grant execute on function public.redeem_classroom_access_pin(text) to authenticated;

drop policy if exists lessons_read_published on public.lessons;
create policy lessons_read_published on public.lessons for select to authenticated using (
  is_published=true and (
    private.has_permission('academics.manage') or
    exists (select 1 from public.learning_access_requests r
      join public.learning_programmes p on p.id=r.programme_id
      join public.classroom_access_passes cap on cap.request_id=r.id
      where r.user_id=(select auth.uid()) and r.status='approved'
        and p.class_id=lessons.class_id and cap.redeemed_at is not null and cap.revoked_at is null) or
    exists (select 1 from public.class_tutors ct join public.tutors t on t.id=ct.tutor_id
      where ct.class_id=lessons.class_id and t.user_id=(select auth.uid()) and t.status='active')
  )
);