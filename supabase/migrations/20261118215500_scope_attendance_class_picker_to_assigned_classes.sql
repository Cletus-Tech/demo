create or replace function private.attendance_available_classes()
returns jsonb language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('id',c.id,'name',c.name,'level',c.level) order by c.name),'[]'::jsonb)
  from public.classes c
  where c.status='active' and private.can_mark_class_attendance(c.id);
$$;
create or replace function public.attendance_available_classes()
returns jsonb language sql security invoker set search_path = ''
as $$ select private.attendance_available_classes(); $$;
revoke all on function private.attendance_available_classes() from public,anon;
grant usage on schema private to authenticated;
grant execute on function private.attendance_available_classes() to authenticated;
revoke all on function public.attendance_available_classes() from public,anon;
grant execute on function public.attendance_available_classes() to authenticated;
