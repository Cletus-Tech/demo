-- 0011_admin_service_request_workflow.sql
create or replace function public.admin_update_service_request(p_id uuid, p_status text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
 if not public.is_admin() then raise exception 'Administrator access required'; end if;
 if p_status not in ('pending','in_review','approved','declined','closed') then raise exception 'Invalid request status'; end if;
 update public.service_requests set status=p_status,admin_note=left(coalesce(p_note,''),2000),updated_at=now() where id=p_id;
 if not found then raise exception 'Service request not found'; end if;
end;
$$;
revoke all on function public.admin_update_service_request(uuid,text,text) from public, anon, authenticated;
grant execute on function public.admin_update_service_request(uuid,text,text) to authenticated;
