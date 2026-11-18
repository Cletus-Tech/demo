-- Daily class attendance with scoped tutor access and learner self-view.
alter table public.attendance_records add column if not exists attendance_date date;
update public.attendance_records set attendance_date=(attended_at at time zone 'Africa/Lagos')::date where attendance_date is null;
alter table public.attendance_records
  alter column attendance_date set default ((now() at time zone 'Africa/Lagos')::date),
  alter column attendance_date set not null,
  add column if not exists session_id uuid references public.academic_sessions(id) on delete set null;
create unique index if not exists attendance_records_student_class_date_uidx on public.attendance_records(student_id,class_id,attendance_date);
create index if not exists attendance_records_class_date_idx on public.attendance_records(class_id,attendance_date);
create index if not exists attendance_records_session_idx on public.attendance_records(session_id);

create or replace function private.can_mark_class_attendance(p_class_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and (
    private.has_permission('students.manage') or private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct join public.tutors t on t.id=ct.tutor_id
      where ct.class_id=p_class_id and t.user_id=auth.uid())
  );
$$;

create or replace function private.class_attendance_roster(p_class_id uuid,p_session_id uuid,p_attendance_date date)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_rows jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_attendance_date is null or p_session_id is null then raise exception 'Choose an academic session and attendance date'; end if;
  if not private.can_mark_class_attendance(p_class_id) then raise exception 'You are not authorised to mark attendance for this class'; end if;
  if not exists(select 1 from public.academic_sessions s where s.id=p_session_id) then raise exception 'Academic session not found'; end if;
  select coalesce(jsonb_agg(jsonb_build_object('student_id',st.id,'admission_number',st.admission_number,
    'full_name',pr.full_name,'attendance_id',ar.id,'status',ar.status,'note',ar.note)
    order by pr.full_name,st.admission_number),'[]'::jsonb)
  into v_rows from public.enrolments e join public.students st on st.id=e.student_id
  left join public.profiles pr on pr.id=st.user_id
  left join public.attendance_records ar on ar.student_id=st.id and ar.class_id=e.class_id and ar.attendance_date=p_attendance_date
  where e.class_id=p_class_id and e.session_id=p_session_id and e.status='active' and st.status='active';
  return v_rows;
end;
$$;

create or replace function private.save_class_attendance(p_class_id uuid,p_session_id uuid,p_attendance_date date,p_marks jsonb)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_item jsonb; v_student_id uuid; v_status text; v_note text; v_saved integer:=0;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_attendance_date is null or p_session_id is null then raise exception 'Choose an academic session and attendance date'; end if;
  if not private.can_mark_class_attendance(p_class_id) then raise exception 'You are not authorised to mark attendance for this class'; end if;
  if jsonb_typeof(p_marks) <> 'array' or jsonb_array_length(p_marks)=0 then raise exception 'No attendance records were supplied'; end if;
  if jsonb_array_length(p_marks)>500 then raise exception 'Attendance batch is too large'; end if;
  for v_item in select value from jsonb_array_elements(p_marks)
  loop
    v_student_id := (v_item->>'student_id')::uuid; v_status := v_item->>'status'; v_note := nullif(btrim(v_item->>'note'),'');
    if v_status not in ('present','absent','late','excused') then raise exception 'Invalid attendance status'; end if;
    if not exists(select 1 from public.enrolments e join public.students st on st.id=e.student_id
      where e.student_id=v_student_id and e.class_id=p_class_id and e.session_id=p_session_id
        and e.status='active' and st.status='active') then
      raise exception 'A selected learner is not actively enrolled in this class and session';
    end if;
    insert into public.attendance_records(student_id,class_id,session_id,attendance_date,status,marked_by,attended_at,note)
    values(v_student_id,p_class_id,p_session_id,p_attendance_date,v_status::public.attendance_status,auth.uid(),
      (p_attendance_date::timestamp at time zone 'Africa/Lagos'),v_note)
    on conflict(student_id,class_id,attendance_date) do update
      set session_id=excluded.session_id,status=excluded.status,marked_by=excluded.marked_by,
        attended_at=excluded.attended_at,note=excluded.note;
    v_saved:=v_saved+1;
  end loop;
  return jsonb_build_object('saved',v_saved,'attendance_date',p_attendance_date);
end;
$$;

create or replace function public.class_attendance_roster(p_class_id uuid,p_session_id uuid,p_attendance_date date)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.class_attendance_roster(p_class_id,p_session_id,p_attendance_date); $$;
create or replace function public.save_class_attendance(p_class_id uuid,p_session_id uuid,p_attendance_date date,p_marks jsonb)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.save_class_attendance(p_class_id,p_session_id,p_attendance_date,p_marks); $$;

revoke all on function private.can_mark_class_attendance(uuid) from public,anon;
revoke all on function private.class_attendance_roster(uuid,uuid,date) from public,anon;
revoke all on function private.save_class_attendance(uuid,uuid,date,jsonb) from public,anon;
grant usage on schema private to authenticated;
grant execute on function private.can_mark_class_attendance(uuid) to authenticated;
grant execute on function private.class_attendance_roster(uuid,uuid,date) to authenticated;
grant execute on function private.save_class_attendance(uuid,uuid,date,jsonb) to authenticated;
revoke all on function public.class_attendance_roster(uuid,uuid,date) from public,anon;
revoke all on function public.save_class_attendance(uuid,uuid,date,jsonb) from public,anon;
grant execute on function public.class_attendance_roster(uuid,uuid,date) to authenticated;
grant execute on function public.save_class_attendance(uuid,uuid,date,jsonb) to authenticated;
