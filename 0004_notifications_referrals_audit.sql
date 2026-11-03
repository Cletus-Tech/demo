-- =====================================================================
-- 0004  Notifications, referrals and the audit log
-- =====================================================================

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  title      text not null check (char_length(title) <= 300),
  body       text,
  kind       text not null default 'info',
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);

create table public.referrals (
  id          uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.profiles (id) on delete cascade,
  referred_id uuid not null unique references public.profiles (id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending','qualified','rewarded')),
  created_at  timestamptz not null default now(),
  check (referrer_id <> referred_id)
);

-- Append-only record of sensitive actions. actor_id is NULL for actions
-- taken directly in the database (for example the first-superadmin step).
create table public.audit_logs (
  id          bigint generated always as identity primary key,
  actor_id    uuid,
  action      text not null,
  target_type text,
  target_id   text,
  details     jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);
create index audit_logs_created_idx on public.audit_logs (created_at desc);

create trigger audit_no_update_delete
  before update or delete on public.audit_logs
  for each row execute function public._block_modification();
create trigger audit_no_truncate
  before truncate on public.audit_logs
  for each statement execute function public._block_modification();

create or replace function public._audit(
  p_action text, p_target_type text, p_target_id text, p_details jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_logs (actor_id, action, target_type, target_id, details)
  values ((select auth.uid()), p_action, p_target_type, p_target_id, coalesce(p_details, '{}'::jsonb));
end $$;

create or replace function public._notify(
  p_user uuid, p_title text, p_kind text default 'info', p_body text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, title, kind, body) values (p_user, p_title, p_kind, p_body);
end $$;

-- Every role or status change is logged, whoever (or whatever) made it.
create or replace function public._audit_profile_changes()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role is distinct from old.role then
    perform public._audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.status is distinct from old.status then
    perform public._audit('status_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.status, 'to', new.status));
  end if;
  return new;
end $$;

create trigger audit_profile_changes
  after update of role, status on public.profiles
  for each row execute function public._audit_profile_changes();

alter table public.notifications enable row level security;
alter table public.referrals     enable row level security;
alter table public.audit_logs    enable row level security;

create policy notifications_select on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));
-- Users may only mark their own notifications read (column grant limits this to read_at).
create policy notifications_update on public.notifications for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy referrals_select on public.referrals for select to authenticated
  using (referrer_id = (select auth.uid()) or referred_id = (select auth.uid()) or public.is_admin());

create policy audit_select on public.audit_logs for select to authenticated
  using (public.is_admin());
