-- Distinguish parent accounts from learner accounts at registration.
-- Parent accounts can request verified guardian links but are not counted as
-- students and do not receive a student profile of their own.

create or replace function public.handle_new_education_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_name text;
  v_account_type text;
begin
  v_name := nullif(btrim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), '');
  if v_name is null then
    v_name := coalesce(nullif(split_part(coalesce(new.email, ''), '@', 1), ''), 'Learner');
  end if;
  v_account_type := lower(coalesce(new.raw_user_meta_data ->> 'account_type','student'));

  insert into public.profiles (id, full_name, email)
  values (new.id, left(v_name, 120), new.email);

  insert into public.user_roles (user_id, role)
  values (new.id, 'external_learner'::public.app_role);

  if v_account_type <> 'parent' and not exists (
    select 1 from public.user_roles ur
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
