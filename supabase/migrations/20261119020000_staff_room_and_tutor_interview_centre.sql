alter type public.app_role add value if not exists 'staff';

create table if not exists public.staff_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  job_title text not null,
  department text,
  status public.record_status not null default 'active',
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id)
);
alter table public.staff_members enable row level security;
revoke all on public.staff_members from anon, authenticated;
grant select, insert, update on public.staff_members to authenticated;
drop policy if exists staff_members_read on public.staff_members;
create policy staff_members_read on public.staff_members for select to authenticated
using (user_id = (select auth.uid()) or private.has_permission('staff.manage'));
drop policy if exists staff_members_manage on public.staff_members;
create policy staff_members_manage on public.staff_members for all to authenticated
using (private.has_permission('staff.manage'))
with check (private.has_permission('staff.manage'));

create table if not exists public.staff_room_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete restrict,
  body text not null check (char_length(trim(body)) between 1 and 5000),
  message_type text not null default 'message' check (message_type in ('message','announcement')),
  pinned boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists staff_room_messages_created_idx on public.staff_room_messages(created_at desc);
alter table public.staff_room_messages enable row level security;
revoke all on public.staff_room_messages from anon, authenticated;
grant select, insert, delete on public.staff_room_messages to authenticated;

create or replace function private.is_staff_room_member()
returns boolean language sql stable security definer set search_path = ''
as $function$
  select auth.uid() is not null and (
    private.has_permission('staff.manage')
    or exists (select 1 from public.tutors t where t.user_id = auth.uid() and t.status = 'active')
    or exists (select 1 from public.staff_members s where s.user_id = auth.uid() and s.status = 'active')
  );
$function$;
revoke all on function private.is_staff_room_member() from public, anon;
grant execute on function private.is_staff_room_member() to authenticated;

drop policy if exists staff_room_messages_read on public.staff_room_messages;
create policy staff_room_messages_read on public.staff_room_messages for select to authenticated
using (private.is_staff_room_member());
drop policy if exists staff_room_messages_post on public.staff_room_messages;
create policy staff_room_messages_post on public.staff_room_messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and private.is_staff_room_member()
  and (message_type = 'message' or private.has_permission('staff.manage') or private.has_permission('communications.send'))
);
drop policy if exists staff_room_messages_delete on public.staff_room_messages;
create policy staff_room_messages_delete on public.staff_room_messages for delete to authenticated
using (private.has_permission('staff.manage'));

create table if not exists public.tutor_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  phone text not null,
  qualification text not null,
  experience_years numeric(4,1) not null default 0 check (experience_years between 0 and 60),
  subjects text[] not null check (cardinality(subjects) > 0),
  class_levels text[] not null check (cardinality(class_levels) > 0),
  introduction text not null check (char_length(trim(introduction)) between 30 and 3000),
  portfolio_url text,
  status text not null default 'submitted' check (status in ('submitted','reviewing','shortlisted','interview_scheduled','approved','rejected')),
  interview_at timestamptz,
  review_note text,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists tutor_applications_status_created_idx on public.tutor_applications(status,created_at desc);
alter table public.tutor_applications enable row level security;
revoke all on public.tutor_applications from anon, authenticated;
grant select, insert on public.tutor_applications to authenticated;
drop policy if exists tutor_applications_read on public.tutor_applications;
create policy tutor_applications_read on public.tutor_applications for select to authenticated
using (user_id = (select auth.uid()) or private.has_permission('staff.manage'));
drop policy if exists tutor_applications_submit on public.tutor_applications;
create policy tutor_applications_submit on public.tutor_applications for insert to authenticated
with check (user_id = (select auth.uid()) and not exists (
  select 1 from public.tutors t where t.user_id = (select auth.uid()) and t.status = 'active'
));

create or replace function private.review_tutor_application(
  p_application_id uuid,
  p_status text,
  p_review_note text default null,
  p_interview_at timestamptz default null
)
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare v_app public.tutor_applications%rowtype;
begin
  if auth.uid() is null or not private.has_permission('staff.manage') then
    raise exception 'You are not authorised to review tutor applications';
  end if;
  if p_status not in ('reviewing','shortlisted','interview_scheduled','approved','rejected') then
    raise exception 'Invalid application status';
  end if;
  if p_status = 'interview_scheduled' and p_interview_at is null then
    raise exception 'Choose an interview date and time';
  end if;
  select * into v_app from public.tutor_applications where id = p_application_id for update;
  if not found then raise exception 'Application not found'; end if;
  update public.tutor_applications set
    status = p_status,
    review_note = nullif(trim(coalesce(p_review_note,'')),''),
    interview_at = case when p_status = 'interview_scheduled' then p_interview_at else interview_at end,
    reviewed_by = auth.uid(), reviewed_at = now(), updated_at = now()
  where id = p_application_id;
  if p_status = 'approved' then
    insert into public.tutors(user_id,qualification,status)
      values(v_app.user_id,v_app.qualification,'active')
      on conflict(user_id) do update set qualification = excluded.qualification, status = 'active';
    insert into public.user_roles(user_id,role) values(v_app.user_id,'tutor')
      on conflict(user_id,role) do nothing;
  end if;
  insert into public.notifications(user_id,title,body)
    values(v_app.user_id,
      case p_status when 'approved' then 'Tutor application approved'
        when 'rejected' then 'Tutor application update'
        when 'interview_scheduled' then 'Tutor interview scheduled'
        else 'Tutor application update' end,
      case p_status when 'approved' then 'Your tutor application has been approved. The centre will contact you with your next onboarding steps.'
        when 'rejected' then coalesce(nullif(trim(coalesce(p_review_note,'')),''),'Thank you for applying. The centre has updated your application status.')
        when 'interview_scheduled' then 'Your interview is scheduled for ' || p_interview_at::text
        else 'Your tutor application status is now ' || replace(p_status,'_',' ') || '.' end);
  return jsonb_build_object('success',true,'status',p_status,'user_id',v_app.user_id);
end;
$function$;
revoke all on function private.review_tutor_application(uuid,text,text,timestamptz) from public, anon, authenticated;
grant execute on function private.review_tutor_application(uuid,text,text,timestamptz) to authenticated;
create or replace function public.review_tutor_application(
  p_application_id uuid,p_status text,p_review_note text default null,p_interview_at timestamptz default null
) returns jsonb language sql security invoker set search_path = ''
as $function$ select private.review_tutor_application(p_application_id,p_status,p_review_note,p_interview_at); $function$;
revoke all on function public.review_tutor_application(uuid,text,text,timestamptz) from public, anon;
grant execute on function public.review_tutor_application(uuid,text,text,timestamptz) to authenticated;
