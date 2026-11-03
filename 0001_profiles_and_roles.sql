-- =====================================================================
-- 0001  Profiles, roles and permission helper functions
-- Run order: 0001 -> 0009 (or just run supabase/setup_all.sql once).
-- =====================================================================

create type public.user_role as enum ('user', 'support', 'admin', 'superadmin');
create type public.account_status as enum ('active', 'suspended');

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create or replace function public.gen_referral_code()
returns text language sql volatile as $$
  select upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8))
$$;

-- One profile per signed-up user (created automatically by a trigger in 0007).
create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  email         text,
  full_name     text check (full_name is null or char_length(full_name) <= 120),
  phone         text check (phone is null or char_length(phone) <= 40),
  country       text check (country is null or char_length(country) <= 80),
  language      text not null default 'en' check (char_length(language) between 2 and 10),
  role          public.user_role not null default 'user',
  status        public.account_status not null default 'active',
  referral_code text not null unique default public.gen_referral_code(),
  referred_by   uuid references public.profiles (id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Permission helpers. SECURITY DEFINER so they can read profiles without
-- recursing into the profiles RLS policies.
create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and status = 'active'
      and role in ('support', 'admin', 'superadmin')
  )
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and status = 'active'
      and role in ('admin', 'superadmin')
  )
$$;

create or replace function public.is_superadmin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and status = 'active'
      and role = 'superadmin'
  )
$$;

-- Row Level Security
alter table public.profiles enable row level security;

create policy profiles_select
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or public.is_staff());

-- Users may update only their own row, and (via column grants in 0009) only
-- full_name, phone, country and language. role/status/email can never be
-- changed by a user.
create policy profiles_update_own
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
