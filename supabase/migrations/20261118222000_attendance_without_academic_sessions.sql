-- Attendance follows approved learning-programme access.
-- Academic sessions remain optional metadata and are no longer required
-- to take a class register.

create or replace function private.class_attendance_roster(
  p_class_id uuid, p_session_id uuid, p_attendance_date date
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare v_rows jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_attendance_date is null then raise exception 'Choose an attendance date'; end if;
  if not private.can_mark_class_attendance(p_class_id) then
    raise exception 'You are not authorised to mark attendance for this class';
  end if;
  with eligible as (
    select distinct st.id as student_id,pr.full_name
    from public.learning_access_requests r
    join public.learning_programmes p on p.id=r.programme_id
    join public.students st on st.user_id=r.user_id and st.status='active'
    left join public.profiles pr on pr.id=st.user_id
    where r.status='approved' and p.class_id=p_class_id and p.is_active=true
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'student_id',e.student_id,'full_name',e.full_name,
    'attendance_id',ar.id,'status',ar.status,'note',ar.note
  ) order by e.full_name),'[]'::jsonb)
  into v_rows
  from eligible e
  left join public.attendance_records ar
    on ar.student_id=e.student_id and ar.class_id=p_class_id
    and ar.attendance_date=p_attendance_date;
  return v_rows;
end;
$$;

create or replace function private.save_class_attendance(
  p_class_id uuid, p_session_id uuid, p_attendance_date date, p_marks jsonb
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_item jsonb; v_student_id uuid; v_status text; v_note text; v_saved integer:=0;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_attendance_date is null then raise exception 'Choose an attendance date'; end if;
  if not private.can_mark_class_attendance(p_class_id) then
    raise exception 'You are not authorised to mark attendance for this class';
  end if;
  if jsonb_typeof(p_marks) <> 'array' or jsonb_array_length(p_marks)=0 then
    raise exception 'No attendance records were supplied';
  end if;
  if jsonb_array_length(p_marks)>500 then raise exception 'Attendance batch is too large'; end if;

  for v_item in select value from jsonb_array_elements(p_marks)
  loop
    v_student_id := (v_item->>'student_id')::uuid;
    v_status := v_item->>'status';
    v_note := nullif(btrim(v_item->>'note'),'');
    if v_status not in ('present','absent','late','excused') then
      raise exception 'Invalid attendance status';
    end if;
    if not exists (
      select 1
      from public.students st
      join public.learning_access_requests r on r.user_id=st.user_id and r.status='approved'
      join public.learning_programmes p on p.id=r.programme_id
      where st.id=v_student_id and st.status='active'
        and p.class_id=p_class_id and p.is_active=true
    ) then
      raise exception 'This learner does not have approved access to the selected class';
    end if;
    insert into public.attendance_records(
      student_id,class_id,session_id,attendance_date,status,marked_by,attended_at,note
    ) values (
      v_student_id,p_class_id,null,p_attendance_date,
      v_status::public.attendance_status,auth.uid(),
      (p_attendance_date::timestamp at time zone 'Africa/Lagos'),v_note
    )
    on conflict(student_id,class_id,attendance_date) do update
      set session_id=null,status=excluded.status,marked_by=excluded.marked_by,
          attended_at=excluded.attended_at,note=excluded.note;
    v_saved:=v_saved+1;
  end loop;
  return jsonb_build_object('saved',v_saved,'attendance_date',p_attendance_date);
end;
$$;
