create or replace function public.admin_assignment_submissions(p_assignment_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.admin_assignment_submissions(p_assignment_id); $$;
revoke all on function public.admin_assignment_submissions(uuid) from public,anon;
grant execute on function public.admin_assignment_submissions(uuid) to authenticated;