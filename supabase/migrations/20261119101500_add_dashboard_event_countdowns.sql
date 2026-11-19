create table if not exists public.dashboard_countdowns (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(trim(title)) between 1 and 100),
  target_at timestamptz not null,
  is_active boolean not null default true,
  tone text not null default 'gold' check (tone in ('gold','blue','green','rose','violet','teal','neon','sunset')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.dashboard_countdowns enable row level security;
drop policy if exists dashboard_countdowns_read_authenticated on public.dashboard_countdowns;
create policy dashboard_countdowns_read_authenticated on public.dashboard_countdowns
for select to authenticated using (true);
drop policy if exists dashboard_countdowns_manage on public.dashboard_countdowns;
create policy dashboard_countdowns_manage on public.dashboard_countdowns
for all to authenticated
using (private.has_permission('communications.send'))
with check (private.has_permission('communications.send'));
create index if not exists dashboard_countdowns_active_target_idx
on public.dashboard_countdowns(is_active,target_at);