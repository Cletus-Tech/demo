create or replace function private.admin_class_tutor_options()
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare v_rows jsonb;
begin
  if auth.uid() is null or not (private.has_permission('academics.manage') or private.has_permission('staff.manage')) then
    raise exception 'You are not authorised to view tutor assignment options';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'tutor_id',t.id,'class_id',ct.class_id,'subject_id',ct.subject_id,'tutor_name',coalesce(p.full_name,'Tutor')
  ) order by p.full_name),'[]'::jsonb)
  into v_rows from public.class_tutors ct
  join public.tutors t on t.id=ct.tutor_id and t.status::text='active'
  left join public.profiles p on p.id=t.user_id;
  return v_rows;
end;
$$;
revoke all on function private.admin_class_tutor_options() from public,anon;
grant execute on function private.admin_class_tutor_options() to authenticated;
create or replace function public.admin_class_tutor_options()
returns jsonb language sql security invoker set search_path=''
as $$ select private.admin_class_tutor_options(); $$;
revoke all on function public.admin_class_tutor_options() from public,anon;
grant execute on function public.admin_class_tutor_options() to authenticated;
