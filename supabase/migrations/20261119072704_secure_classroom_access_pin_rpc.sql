create or replace function public.issue_classroom_access_pin(p_request_id uuid)
returns text language sql security definer set search_path = ''
as $$ select private.issue_classroom_access_pin(p_request_id); $$;
create or replace function public.redeem_classroom_access_pin(p_pin text)
returns boolean language sql security definer set search_path = ''
as $$ select private.redeem_classroom_access_pin(p_pin); $$;
revoke all on function public.issue_classroom_access_pin(uuid) from public, anon;
revoke all on function public.redeem_classroom_access_pin(text) from public, anon;
grant execute on function public.issue_classroom_access_pin(uuid) to authenticated;
grant execute on function public.redeem_classroom_access_pin(text) to authenticated;