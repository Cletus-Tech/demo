create or replace function public.handle_new_education_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_name text;
begin
  v_name := nullif(btrim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), '');
  if v_name is null then
    v_name := coalesce(nullif(split_part(coalesce(new.email, ''), '@', 1), ''), 'Learner');
  end if;

  insert into public.profiles (id, full_name, email)
  values (new.id, left(v_name, 120), new.email);

  insert into public.user_roles (user_id, role)
  values (new.id, 'external_learner'::public.app_role);

  -- Public self-registration creates a learner record automatically.
  -- Staff and administrator accounts are deliberately not enrolled as students.
  if not exists (
    select 1
    from public.user_roles ur
    where ur.user_id = new.id
      and ur.role::text in ('admin', 'super_admin', 'tutor')
  ) then
    insert into public.students (user_id)
    values (new.id)
    on conflict (user_id) do nothing;
  end if;

  return new;
end;
$function$;

-- Repair learner accounts created before the student-record link was added.
insert into public.students (user_id)
select u.id
from auth.users u
join public.profiles p on p.id = u.id
where exists (
  select 1 from public.user_roles ur
  where ur.user_id = u.id and ur.role::text = 'external_learner'
)
and not exists (
  select 1 from public.user_roles ur
  where ur.user_id = u.id and ur.role::text in ('admin', 'super_admin', 'tutor')
)
and not exists (
  select 1 from public.students s where s.user_id = u.id
);
