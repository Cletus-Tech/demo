create or replace function private.sync_notification_announcement_target()
returns trigger
language plpgsql
set search_path to ''
as $function$
begin
  if new.announcement_id is not null then
    new.target_type := 'announcement';
    new.target_id := new.announcement_id;
  elsif tg_op = 'UPDATE'
    and old.announcement_id is not null
    and new.announcement_id is null
    and old.target_type = 'announcement'
    and old.target_id = old.announcement_id then
    new.target_type := null;
    new.target_id := null;
  end if;
  return new;
end;
$function$;

update public.notifications n
set target_type='learning_access',
    target_id=(
      select r.id
      from public.learning_access_requests r
      where r.user_id=n.user_id
        and r.status='approved'
        and r.created_at<=n.created_at
      order by abs(extract(epoch from (n.created_at-coalesce(r.updated_at,r.created_at))))
      limit 1
    )
where n.target_type is null
  and n.title in ('Your classroom pass is ready','Learning access approved')
  and exists (
    select 1 from public.learning_access_requests r
    where r.user_id=n.user_id and r.status='approved' and r.created_at<=n.created_at
  );

update public.notifications n
set target_type='parent_link',
    target_id=(
      select q.id
      from public.guardian_link_requests q
      where q.guardian_user_id=n.user_id
        and q.status='approved'
        and q.reviewed_at<=n.created_at
      order by abs(extract(epoch from (n.created_at-q.reviewed_at)))
      limit 1
    )
where n.target_type is null
  and n.title='Child account linked'
  and exists (
    select 1 from public.guardian_link_requests q
    where q.guardian_user_id=n.user_id and q.status='approved' and q.reviewed_at<=n.created_at
  );

update public.notifications n
set target_type='tutor_application',
    target_id=(
      select a.id
      from public.tutor_applications a
      where a.user_id=n.user_id
        and a.reviewed_at<=n.created_at
      order by abs(extract(epoch from (n.created_at-a.reviewed_at)))
      limit 1
    )
where n.target_type is null
  and n.title in ('Tutor application approved','Tutor application update')
  and exists (
    select 1 from public.tutor_applications a
    where a.user_id=n.user_id and a.reviewed_at<=n.created_at
  );
