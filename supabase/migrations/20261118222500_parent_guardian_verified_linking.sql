-- Parent/guardian account linking is always a centre-reviewed request.
-- A guardian can request a link using the learner's sign-in email, but cannot
-- read learner records until an authorised administrator approves it.

alter table public.student_guardians
  add column if not exists relationship text;

create table if not exists public.guardian_link_requests (
  id uuid primary key default gen_random_uuid(),
  guardian_user_id uuid not null references public.profiles(id) on delete cascade,
  guardian_id uuid not null references public.guardians(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  requested_email text not null,
  relationship text not null default 'Parent',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  admin_note text,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.guardian_link_requests enable row level security;
revoke all on public.guardian_link_requests from anon, authenticated;
create policy guardian_link_requests_no_direct_access on public.guardian_link_requests
  for all to authenticated using (false) with check (false);
create index if not exists guardian_link_requests_status_created_idx
  on public.guardian_link_requests(status,created_at desc);
create index if not exists guardian_link_requests_guardian_user_idx
  on public.guardian_link_requests(guardian_user_id);
create index if not exists student_guardians_guardian_id_idx
  on public.student_guardians(guardian_id);

create or replace function private.request_guardian_link(
  p_student_email text, p_relationship text default 'Parent'
) returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_guardian_id uuid; v_student_id uuid; v_email text; v_relationship text;
begin
  if auth.uid() is null then raise exception 'Sign in to submit a parent link request'; end if;
  v_email := lower(btrim(coalesce(p_student_email,'')));
  v_relationship := left(nullif(btrim(coalesce(p_relationship,'')),''),40);
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Enter the learner account email address';
  end if;
  if v_relationship is null then v_relationship := 'Parent'; end if;

  insert into public.guardians(user_id,relationship)
  values(auth.uid(),v_relationship)
  on conflict(user_id) do update set relationship=excluded.relationship
  returning id into v_guardian_id;

  select st.id into v_student_id
  from public.profiles pr
  join public.students st on st.user_id=pr.id and st.status='active'
  where lower(pr.email)=v_email and pr.id<>auth.uid()
  limit 1;

  if exists (
    select 1 from public.guardian_link_requests q
    where q.guardian_user_id=auth.uid() and lower(q.requested_email)=v_email and q.status='pending'
  ) then
    return jsonb_build_object('status','pending','message','Your request is already awaiting review.');
  end if;

  insert into public.guardian_link_requests(
    guardian_user_id,guardian_id,student_id,requested_email,relationship,status
  ) values (
    auth.uid(),v_guardian_id,v_student_id,v_email,v_relationship,'pending'
  );
  return jsonb_build_object('status','pending','message','Your request has been sent for centre verification.');
end;
$$;

create or replace function private.guardian_portal_summary()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_guardian_id uuid; v_children jsonb; v_requests jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in to view your parent dashboard'; end if;
  select g.id into v_guardian_id from public.guardians g where g.user_id=auth.uid();
  if v_guardian_id is null then
    return jsonb_build_object('children','[]'::jsonb,'requests','[]'::jsonb);
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'student_id',st.id,'name',pr.full_name,'email',pr.email,
    'level',st.level,'relationship',sg.relationship,'status',st.status,
    'attendance_total',(select count(*) from public.attendance_records ar where ar.student_id=st.id),
    'attendance_rate',(
      select case when count(*)=0 then null
        else round((count(*) filter (where ar.status in ('present','late'))::numeric/count(*))*100,1)
      end from public.attendance_records ar where ar.student_id=st.id
    ),
    'assignments_submitted',(select count(*) from public.assignment_submissions ass where ass.student_id=st.id and ass.submitted_at is not null),
    'latest_result',(select res.score from public.results res where res.student_id=st.id and res.published_at is not null order by res.published_at desc limit 1),
    'latest_subject',(select su.name from public.results res join public.subjects su on su.id=res.subject_id where res.student_id=st.id and res.published_at is not null order by res.published_at desc limit 1),
    'latest_comment',(select res.tutor_comment from public.results res where res.student_id=st.id and res.published_at is not null order by res.published_at desc limit 1)
  ) order by pr.full_name),'[]'::jsonb)
  into v_children
  from public.student_guardians sg
  join public.students st on st.id=sg.student_id
  join public.profiles pr on pr.id=st.user_id
  where sg.guardian_id=v_guardian_id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id',q.id,'requested_email',q.requested_email,'relationship',q.relationship,
    'status',q.status,'admin_note',q.admin_note,'created_at',q.created_at
  ) order by q.created_at desc),'[]'::jsonb)
  into v_requests
  from public.guardian_link_requests q where q.guardian_user_id=auth.uid();

  return jsonb_build_object('children',v_children,'requests',v_requests);
end;
$$;

create or replace function private.admin_guardian_link_requests()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_rows jsonb;
begin
  if auth.uid() is null or not private.has_permission('students.manage') then
    raise exception 'You are not authorised to review parent link requests';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',q.id,'guardian_name',gp.full_name,'guardian_email',gp.email,
    'student_name',sp.full_name,'requested_email',q.requested_email,
    'relationship',q.relationship,'status',q.status,'admin_note',q.admin_note,
    'created_at',q.created_at,'student_id',q.student_id
  ) order by q.created_at desc),'[]'::jsonb)
  into v_rows
  from public.guardian_link_requests q
  join public.profiles gp on gp.id=q.guardian_user_id
  left join public.students st on st.id=q.student_id
  left join public.profiles sp on sp.id=st.user_id
  where q.status='pending';
  return v_rows;
end;
$$;

create or replace function private.review_guardian_link_request(
  p_request_id uuid,p_decision text,p_admin_note text default null
) returns void language plpgsql security definer set search_path = ''
as $$
declare
  v_guardian_id uuid; v_student_id uuid; v_guardian_user uuid;
  v_student_name text; v_relationship text;
begin
  if auth.uid() is null or not private.has_permission('students.manage') then
    raise exception 'You are not authorised to review parent link requests';
  end if;
  if p_decision not in ('approved','rejected') then raise exception 'Choose approve or reject'; end if;
  select q.guardian_id,q.student_id,q.guardian_user_id,sp.full_name,q.relationship
  into v_guardian_id,v_student_id,v_guardian_user,v_student_name,v_relationship
  from public.guardian_link_requests q
  left join public.students st on st.id=q.student_id
  left join public.profiles sp on sp.id=st.user_id
  where q.id=p_request_id and q.status='pending'
  for update of q;
  if not found then raise exception 'This parent link request is no longer pending'; end if;
  if p_decision='approved' then
    if v_student_id is null then raise exception 'No matching active learner account was found for this email. Ask the parent to check the email and submit again.'; end if;
    insert into public.student_guardians(student_id,guardian_id,relationship)
    values(v_student_id,v_guardian_id,v_relationship)
    on conflict(student_id,guardian_id) do update set relationship=excluded.relationship;
  end if;
  update public.guardian_link_requests
  set status=p_decision,admin_note=nullif(btrim(coalesce(p_admin_note,'')),''),
      reviewed_by=auth.uid(),reviewed_at=now()
  where id=p_request_id;
  insert into public.notifications(user_id,title,body)
  values(
    v_guardian_user,
    case when p_decision='approved' then 'Child account linked' else 'Parent link request reviewed' end,
    case when p_decision='approved'
      then coalesce(v_student_name,'The learner') || ' has been linked to your parent dashboard.'
      else 'Your parent link request was not approved. Please check the learner email or contact the centre.'
    end || case when nullif(btrim(coalesce(p_admin_note,'')),'') is null then '' else ' Note: ' || btrim(p_admin_note) end
  );
end;
$$;

create or replace function public.request_guardian_link(p_student_email text,p_relationship text default 'Parent')
returns jsonb language sql set search_path = '' as $$
  select private.request_guardian_link(p_student_email,p_relationship);
$$;
create or replace function public.guardian_portal_summary()
returns jsonb language sql set search_path = '' as $$
  select private.guardian_portal_summary();
$$;
create or replace function public.admin_guardian_link_requests()
returns jsonb language sql set search_path = '' as $$
  select private.admin_guardian_link_requests();
$$;
create or replace function public.review_guardian_link_request(p_request_id uuid,p_decision text,p_admin_note text default null)
returns void language sql set search_path = '' as $$
  select private.review_guardian_link_request(p_request_id,p_decision,p_admin_note);
$$;

revoke all on function public.request_guardian_link(text,text) from public,anon;
revoke all on function public.guardian_portal_summary() from public,anon;
revoke all on function public.admin_guardian_link_requests() from public,anon;
revoke all on function public.review_guardian_link_request(uuid,text,text) from public,anon;
grant execute on function public.request_guardian_link(text,text) to authenticated;
grant execute on function public.guardian_portal_summary() to authenticated;
grant execute on function public.admin_guardian_link_requests() to authenticated;
grant execute on function public.review_guardian_link_request(uuid,text,text) to authenticated;
