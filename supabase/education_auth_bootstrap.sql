-- Applied to Supabase project lvpetmhhspuagbjojlks on 2026-11-18.
-- Education-only signup bootstrap. New self-registered accounts are external learners.
-- Centre staff must provision student, guardian, tutor and admin roles separately.
create or replace function public.handle_new_education_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_name text;
begin
  v_name := nullif(btrim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), '');
  if v_name is null then
    v_name := coalesce(nullif(split_part(coalesce(new.email, ''), '@', 1), ''), 'Learner');
  end if;
  insert into public.profiles (id, full_name, email)
  values (new.id, left(v_name, 120), new.email);
  insert into public.user_roles (user_id, role)
  values (new.id, 'external_learner'::public.app_role);
  return new;
end;
$$;
revoke all on function public.handle_new_education_user() from public, anon, authenticated;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    execute 'grant execute on function public.handle_new_education_user() to supabase_auth_admin';
  end if;
end;
$$;
drop trigger if exists on_education_user_created on auth.users;
create trigger on_education_user_created after insert on auth.users
for each row execute function public.handle_new_education_user();

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
drop policy if exists profiles_read_own on public.profiles;
create policy profiles_read_own on public.profiles for select to authenticated
using ((select auth.uid()) = id);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
drop policy if exists user_roles_read_own on public.user_roles;
create policy user_roles_read_own on public.user_roles for select to authenticated
using ((select auth.uid()) = user_id);
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, phone, avatar_url) on public.profiles to authenticated;
revoke all on public.user_roles from anon, authenticated;
grant select on public.user_roles to authenticated;
