-- Preserve dashboard posts independently so the billboard can rotate.
with ordered as (
  select id, created_at,
         lead(published_at) over (partition by target_class_id order by published_at, created_at) as next_published_at
  from public.announcements where published_at is not null
)
update public.announcements a
set expires_at = o.created_at + interval '7 days'
from ordered o
where a.id = o.id and o.next_published_at is not null and a.expires_at = o.next_published_at;

create or replace function private.publish_dashboard_announcement(
  _title text, _body text, _notify_students boolean default true,
  _expires_at timestamptz default null, _target_class_id uuid default null,
  _banner_tone text default 'gold', _attachment_path text default null,
  _attachment_name text default null, _attachment_mime_type text default null,
  _attachment_size bigint default null
) returns integer language plpgsql security definer set search_path = ''
as $function$
declare sent_count integer := 0;
begin
  if auth.uid() is null or not private.has_permission('communications.send') then
    raise exception 'You do not have permission to publish dashboard updates';
  end if;
  if length(trim(coalesce(_title,'')))=0 or length(trim(coalesce(_body,'')))=0 then
    raise exception 'A title and message are required';
  end if;
  if _expires_at is not null and _expires_at<=now() then
    raise exception 'Expiry must be in the future';
  end if;
  if _banner_tone not in ('gold','blue','green','rose','ocean','violet','teal','sunset','emerald','midnight','neon','aurora','royal','coral') then
    raise exception 'Invalid banner style';
  end if;
  if _target_class_id is not null and not exists(select 1 from public.classes where id=_target_class_id and status='active') then
    raise exception 'Choose an active class';
  end if;
  if _attachment_path is not null and (
    _attachment_path !~ ('^announcements/'||auth.uid()::text||'/')
    or _attachment_name is null or _attachment_mime_type is null
    or _attachment_size is null or _attachment_size<1 or _attachment_size>52428800
  ) then raise exception 'Invalid announcement attachment'; end if;

  -- Keep previous notices active until their own expiry date.
  insert into public.announcements
    (title,body,audience,published_at,created_by,expires_at,target_class_id,banner_tone,attachment_path,attachment_name,attachment_mime_type,attachment_size)
  values
    (trim(_title),trim(_body),null,now(),auth.uid(),_expires_at,_target_class_id,_banner_tone,_attachment_path,_attachment_name,_attachment_mime_type,_attachment_size);

  if coalesce(_notify_students,true) then
    insert into public.notifications(user_id,title,body)
    select distinct s.user_id,trim(_title),trim(_body) from public.students s
    where s.user_id is not null and (_target_class_id is null or exists(
      select 1 from public.classes c where c.id=_target_class_id
      and regexp_replace(upper(s.level),'[^A-Z0-9]','','g')=regexp_replace(upper(c.name),'[^A-Z0-9]','','g')
    ));
    get diagnostics sent_count=row_count;
  end if;
  insert into public.audit_logs(actor_id,action,entity_type,details)
  values(auth.uid(),'dashboard_announcement_published','announcement',
    jsonb_build_object('title',trim(_title),'target_class_id',_target_class_id,'expires_at',_expires_at,
      'attachment_name',_attachment_name,'student_notifications_sent',sent_count));
  return sent_count;
end;
$function$;