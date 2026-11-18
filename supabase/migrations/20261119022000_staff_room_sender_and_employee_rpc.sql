alter table public.staff_room_messages add column if not exists sender_name text;

create or replace function private.staff_room_message_set_sender()
returns trigger language plpgsql security definer set search_path = ''
as $function$
begin
  select p.full_name into new.sender_name from public.profiles p where p.id = new.sender_id;
  if new.sender_name is null or trim(new.sender_name) = '' then new.sender_name := 'Staff member'; end if;
  return new;
end;
$function$;
revoke all on function private.staff_room_message_set_sender() from public, anon, authenticated;
drop trigger if exists staff_room_message_sender_name on public.staff_room_messages;
create trigger staff_room_message_sender_name before insert on public.staff_room_messages
for each row execute function private.staff_room_message_set_sender();

create or replace function private.is_staff_room_member()
returns boolean language sql stable security definer set search_path = ''
as $function$
  select auth.uid() is not null and (
    private.has_permission('staff.manage')
    or private.has_permission('communications.send')
    or exists (select 1 from public.tutors t where t.user_id = auth.uid() and t.status = 'active')
    or exists (select 1 from public.staff_members s where s.user_id = auth.uid() and s.status = 'active')
  );
$function$;
revoke all on function private.is_staff_room_member() from public, anon;
grant execute on function private.is_staff_room_member() to authenticated;

create or replace function private.add_staff_member(p_user_id uuid,p_job_title text,p_department text default null)
returns uuid language plpgsql security definer set search_path = ''
as $function$
declare v_id uuid;
begin
  if auth.uid() is null or not private.has_permission('staff.manage') then raise exception 'Not authorised'; end if;
  if p_user_id is null or nullif(trim(coalesce(p_job_title,'')),'') is null then raise exception 'Choose an account and job title'; end if;
  if exists(select 1 from public.tutors t where t.user_id=p_user_id and t.status='active') then raise exception 'This account is already an active tutor'; end if;
  insert into public.staff_members(user_id,job_title,department,created_by)
    values(p_user_id,trim(p_job_title),nullif(trim(coalesce(p_department,'')),''),auth.uid())
    returning id into v_id;
  insert into public.user_roles(user_id,role) values(p_user_id,'staff') on conflict(user_id,role) do nothing;
  return v_id;
end;
$function$;
revoke all on function private.add_staff_member(uuid,text,text) from public, anon, authenticated;
grant execute on function private.add_staff_member(uuid,text,text) to authenticated;
create or replace function public.add_staff_member(p_user_id uuid,p_job_title text,p_department text default null)
returns uuid language sql security invoker set search_path = ''
as $function$ select private.add_staff_member(p_user_id,p_job_title,p_department); $function$;
revoke all on function public.add_staff_member(uuid,text,text) from public, anon;
grant execute on function public.add_staff_member(uuid,text,text) to authenticated;
