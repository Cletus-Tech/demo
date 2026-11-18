create or replace function private.sync_staff_member_role()
returns trigger language plpgsql security definer set search_path = ''
as $function$
begin
  if tg_op = 'DELETE' or new.status <> 'active' then
    delete from public.user_roles where user_id = coalesce(new.user_id,old.user_id) and role = 'staff';
  else
    insert into public.user_roles(user_id,role) values(new.user_id,'staff')
      on conflict(user_id,role) do nothing;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$function$;
revoke all on function private.sync_staff_member_role() from public,anon,authenticated;
drop trigger if exists staff_member_role_sync on public.staff_members;
create trigger staff_member_role_sync after insert or update of status or delete on public.staff_members
for each row execute function private.sync_staff_member_role();