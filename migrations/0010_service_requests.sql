-- 0010_service_requests.sql
-- Demo-only customer service enquiries. No payment, custody or investment execution.
create table if not exists public.service_requests (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 service_key text not null check (service_key in ('cold_storage','cards','subscribe','signals','connect_wallet','investing','copy_trading','mining','real_estate','stake')),
 details text not null default '' check (char_length(details) <= 2000),
 status text not null default 'pending' check (status in ('pending','in_review','approved','declined','closed')),
 admin_note text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists service_requests_user_created_idx on public.service_requests(user_id,created_at desc);
alter table public.service_requests enable row level security;
drop policy if exists service_requests_select_own_or_admin on public.service_requests;
create policy service_requests_select_own_or_admin on public.service_requests for select to authenticated using (user_id = (select auth.uid()) or public.is_admin());
drop policy if exists service_requests_insert_own on public.service_requests;
create policy service_requests_insert_own on public.service_requests for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending' and admin_note is null);
grant select, insert on public.service_requests to authenticated;
revoke update, delete on public.service_requests from anon, authenticated;
