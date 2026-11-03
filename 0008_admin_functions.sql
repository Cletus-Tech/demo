-- =====================================================================
-- 0008  Minimal admin functions (the full admin dashboard is Stage 3)
-- =====================================================================

-- Only a superadmin can change roles, never their own, and every change is
-- written to audit_logs by the trigger in 0004.
create or replace function public.admin_set_role(p_user uuid, p_role public.user_role)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_superadmin() then
    raise exception 'Only a superadmin can change roles';
  end if;
  if p_user = (select auth.uid()) then
    raise exception 'You cannot change your own role';
  end if;
  update public.profiles set role = p_role where id = p_user;
  if not found then
    raise exception 'User not found';
  end if;
end $$;

-- Admins can suspend/reactivate ordinary users. Only a superadmin can
-- suspend another admin or superadmin. Nobody can suspend themselves.
create or replace function public.admin_set_status(p_user uuid, p_status public.account_status)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_target_role public.user_role;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;
  if p_user = (select auth.uid()) then
    raise exception 'You cannot change your own status';
  end if;
  select role into v_target_role from public.profiles where id = p_user;
  if v_target_role is null then
    raise exception 'User not found';
  end if;
  if v_target_role in ('admin', 'superadmin') and not public.is_superadmin() then
    raise exception 'Only a superadmin can change another admin''s status';
  end if;
  update public.profiles set status = p_status where id = p_user;
end $$;

-- ONE-TIME SETUP HELPER. Run it yourself in the Supabase SQL Editor after you
-- have signed up in the app:   select public.bootstrap_superadmin('you@example.com');
-- It is not callable from the browser (see 0009).
create or replace function public.bootstrap_superadmin(p_email text)
returns void language plpgsql as $$
begin
  update public.profiles set role = 'superadmin' where lower(email) = lower(p_email);
  if not found then
    raise exception 'No user with email % - sign up in the app first', p_email;
  end if;
end $$;
