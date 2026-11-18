-- Core programme, bank-transfer and classroom-access model.
-- This is intentionally a small manual-payment workflow: no payment gateway
-- or third-party checkout dependency is required.

create table if not exists public.learning_programmes (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(btrim(title)) between 3 and 120),
  stage text not null check (stage in ('Primary','JSS','SS')),
  level text not null,
  description text,
  duration_label text not null default 'Monthly',
  fee numeric not null check (fee > 0),
  class_id uuid references public.classes(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learning_payment_settings (
  id smallint primary key default 1 check (id = 1),
  bank_name text,
  account_name text,
  account_number text,
  payment_instructions text,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

create table if not exists public.learning_access_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  learner_name text not null,
  level text not null,
  programme_id uuid not null references public.learning_programmes(id),
  programme_title text not null,
  amount_due numeric not null check (amount_due > 0),
  status text not null default 'awaiting_payment'
    check (status in ('awaiting_payment','payment_submitted','approved','rejected')),
  payment_amount numeric,
  payment_reference text,
  payment_note text,
  admin_note text,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.learning_programmes enable row level security;
alter table public.learning_payment_settings enable row level security;
alter table public.learning_access_requests enable row level security;

grant select,insert,update,delete on public.learning_programmes to authenticated;
grant select,insert,update on public.learning_payment_settings to authenticated;
grant select on public.learning_access_requests to authenticated;

drop policy if exists learning_programmes_read on public.learning_programmes;
create policy learning_programmes_read on public.learning_programmes for select to authenticated
using (
  is_active
  or private.has_permission('academics.manage')
  or exists (
    select 1 from public.learning_access_requests r
    where r.programme_id=learning_programmes.id
      and r.user_id=(select auth.uid()) and r.status='approved'
  )
);
drop policy if exists learning_programmes_admin_insert on public.learning_programmes;
create policy learning_programmes_admin_insert on public.learning_programmes for insert to authenticated
with check (private.has_permission('academics.manage'));
drop policy if exists learning_programmes_admin_update on public.learning_programmes;
create policy learning_programmes_admin_update on public.learning_programmes for update to authenticated
using (private.has_permission('academics.manage'))
with check (private.has_permission('academics.manage'));
drop policy if exists learning_programmes_admin_delete on public.learning_programmes;
create policy learning_programmes_admin_delete on public.learning_programmes for delete to authenticated
using (private.has_permission('academics.manage'));

drop policy if exists learning_payment_settings_read on public.learning_payment_settings;
create policy learning_payment_settings_read on public.learning_payment_settings for select to authenticated
using (true);
drop policy if exists learning_payment_settings_admin_insert on public.learning_payment_settings;
create policy learning_payment_settings_admin_insert on public.learning_payment_settings for insert to authenticated
with check (private.has_permission('finance.manage'));
drop policy if exists learning_payment_settings_admin_update on public.learning_payment_settings;
create policy learning_payment_settings_admin_update on public.learning_payment_settings for update to authenticated
using (private.has_permission('finance.manage'))
with check (private.has_permission('finance.manage'));

drop policy if exists learning_access_requests_read on public.learning_access_requests;
create policy learning_access_requests_read on public.learning_access_requests for select to authenticated
using (
  user_id=(select auth.uid())
  or private.has_permission('students.manage')
  or private.has_permission('finance.manage')
);

create index if not exists learning_programmes_active_idx
  on public.learning_programmes(is_active,stage,level);
create index if not exists learning_programmes_class_idx
  on public.learning_programmes(class_id);
create index if not exists learning_access_requests_user_idx
  on public.learning_access_requests(user_id,created_at desc);
create index if not exists learning_access_requests_status_idx
  on public.learning_access_requests(status,created_at);
create index if not exists learning_access_requests_programme_idx
  on public.learning_access_requests(programme_id);
create index if not exists learning_access_requests_reviewed_by_idx
  on public.learning_access_requests(reviewed_by);
create index if not exists learning_payment_settings_updated_by_idx
  on public.learning_payment_settings(updated_by);

create or replace function private.create_learning_access_request(
  p_programme_id uuid,p_learner_name text,p_level text
) returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_programme public.learning_programmes%rowtype; v_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  if length(btrim(coalesce(p_learner_name,''))) < 2 then raise exception 'Enter the learner name'; end if;
  if length(btrim(coalesce(p_level,''))) < 2 then raise exception 'Choose a learning level'; end if;
  select * into v_programme from public.learning_programmes
    where id=p_programme_id and is_active=true;
  if not found then raise exception 'This learning programme is no longer available'; end if;
  if exists (
    select 1 from public.learning_access_requests r
    where r.user_id=auth.uid() and r.programme_id=p_programme_id
      and r.status in ('awaiting_payment','payment_submitted','approved')
  ) then raise exception 'You already have an active request for this programme'; end if;
  insert into public.learning_access_requests(
    user_id,learner_name,level,programme_id,programme_title,amount_due,status
  ) values (
    auth.uid(),btrim(p_learner_name),btrim(p_level),v_programme.id,
    v_programme.title,v_programme.fee,'awaiting_payment'
  ) returning id into v_id;
  return v_id;
end;
$$;

create or replace function private.submit_learning_payment(
  p_request_id uuid,p_amount numeric,p_reference text,p_note text default null
) returns void language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  if p_amount is null or p_amount<=0 then raise exception 'Enter the amount you paid'; end if;
  if length(btrim(coalesce(p_reference,'')))<3 then raise exception 'Enter your bank transfer reference'; end if;
  update public.learning_access_requests
  set payment_amount=p_amount,payment_reference=btrim(p_reference),
      payment_note=nullif(btrim(coalesce(p_note,'')),''),
      status='payment_submitted',updated_at=now()
  where id=p_request_id and user_id=auth.uid()
    and status in ('awaiting_payment','rejected');
  if not found then raise exception 'This request cannot accept a payment submission'; end if;
end;
$$;

create or replace function private.review_learning_access_request(
  p_request_id uuid,p_decision text,p_admin_note text default null
) returns void language plpgsql security definer set search_path = ''
as $$
declare v_user_id uuid; v_title text;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  if not (private.has_permission('finance.manage') or private.has_permission('students.manage')) then
    raise exception 'You are not authorised to review learning requests';
  end if;
  if p_decision not in ('approved','rejected') then raise exception 'Choose approve or reject'; end if;
  update public.learning_access_requests
  set status=p_decision,admin_note=nullif(btrim(coalesce(p_admin_note,'')),''),
      reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now()
  where id=p_request_id and status='payment_submitted'
    and (p_decision='rejected' or payment_amount>=amount_due)
  returning user_id,programme_title into v_user_id,v_title;
  if not found then
    raise exception 'The request is unavailable, or the reported payment is below the programme fee and cannot be approved. You can reject it and ask the learner to resubmit.';
  end if;
  insert into public.notifications(user_id,title,body)
  values(
    v_user_id,
    case when p_decision='approved' then 'Learning access approved' else 'Payment needs attention' end,
    case when p_decision='approved'
      then 'Your payment for '||v_title||' has been verified. Your classroom access is now approved.'
      else 'Your payment for '||v_title||' was not approved. Please review the note and resubmit your payment details.'
    end || case when nullif(btrim(coalesce(p_admin_note,'')),'') is null then '' else ' Admin note: '||btrim(p_admin_note) end
  );
end;
$$;

create or replace function public.create_learning_access_request(
  p_programme_id uuid,p_learner_name text,p_level text
) returns uuid language sql set search_path = '' as $$
  select private.create_learning_access_request(p_programme_id,p_learner_name,p_level);
$$;
create or replace function public.submit_learning_payment(
  p_request_id uuid,p_amount numeric,p_reference text,p_note text default null
) returns void language sql set search_path = '' as $$
  select private.submit_learning_payment(p_request_id,p_amount,p_reference,p_note);
$$;
create or replace function public.review_learning_access_request(
  p_request_id uuid,p_decision text,p_admin_note text default null
) returns void language sql set search_path = '' as $$
  select private.review_learning_access_request(p_request_id,p_decision,p_admin_note);
$$;

revoke all on function public.create_learning_access_request(uuid,text,text) from public,anon;
revoke all on function public.submit_learning_payment(uuid,numeric,text,text) from public,anon;
revoke all on function public.review_learning_access_request(uuid,text,text) from public,anon;
grant execute on function public.create_learning_access_request(uuid,text,text) to authenticated;
grant execute on function public.submit_learning_payment(uuid,numeric,text,text) to authenticated;
grant execute on function public.review_learning_access_request(uuid,text,text) to authenticated;
grant execute on function private.create_learning_access_request(uuid,text,text) to authenticated;
grant execute on function private.submit_learning_payment(uuid,numeric,text,text) to authenticated;
grant execute on function private.review_learning_access_request(uuid,text,text) to authenticated;
