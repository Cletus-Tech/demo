-- Provide a permission-checked directory of all registered accounts.
-- user_roles is intentionally private to each user, so admins access role
-- labels through this narrowly scoped function instead of broad table access.

create or replace function private.admin_registered_accounts()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_rows jsonb;
begin
  if auth.uid() is null or not private.has_permission('students.manage') then
    raise exception 'You are not authorised to view registered accounts';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,
    'full_name',p.full_name,
    'email',p.email,
    'account_type',p.account_type,
    'created_at',p.created_at,
    'roles',coalesce((
      select jsonb_agg(jsonb_build_object('role',ur.role) order by ur.role::text)
      from public.user_roles ur where ur.user_id=p.id
    ),'[]'::jsonb),
    'student',(
      select jsonb_build_object('id',st.id,'level',st.level,'status',st.status)
      from public.students st where st.user_id=p.id limit 1
    )
  ) order by p.created_at desc),'[]'::jsonb)
  into v_rows
  from public.profiles p;
  return v_rows;
end;
$$;

create or replace function public.admin_registered_accounts()
returns jsonb language sql set search_path = '' as $$
  select private.admin_registered_accounts();
$$;
revoke all on function public.admin_registered_accounts() from public,anon;
grant execute on function public.admin_registered_accounts() to authenticated;
