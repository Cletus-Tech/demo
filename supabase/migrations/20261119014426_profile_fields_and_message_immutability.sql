-- Bring profile editing and direct-message access hardening under migration control.
alter table public.profiles
  add column if not exists about_me text,
  add column if not exists occupation text,
  add column if not exists profile_class text,
  add column if not exists interests text,
  add column if not exists skills text,
  add column if not exists aspirations text;

do $$
begin
  if not exists (select 1 from pg_constraint where conrelid='public.profiles'::regclass and conname='profiles_about_me_length_check') then
    alter table public.profiles add constraint profiles_about_me_length_check check (about_me is null or char_length(about_me) <= 600);
  end if;
  if not exists (select 1 from pg_constraint where conrelid='public.profiles'::regclass and conname='profiles_occupation_length_check') then
    alter table public.profiles add constraint profiles_occupation_length_check check (occupation is null or char_length(occupation) <= 100);
  end if;
  if not exists (select 1 from pg_constraint where conrelid='public.profiles'::regclass and conname='profiles_profile_class_length_check') then
    alter table public.profiles add constraint profiles_profile_class_length_check check (profile_class is null or char_length(profile_class) <= 80);
  end if;
  if not exists (select 1 from pg_constraint where conrelid='public.profiles'::regclass and conname='profiles_interests_length_check') then
    alter table public.profiles add constraint profiles_interests_length_check check (interests is null or char_length(interests) <= 300);
  end if;
  if not exists (select 1 from pg_constraint where conrelid='public.profiles'::regclass and conname='profiles_skills_length_check') then
    alter table public.profiles add constraint profiles_skills_length_check check (skills is null or char_length(skills) <= 300);
  end if;
  if not exists (select 1 from pg_constraint where conrelid='public.profiles'::regclass and conname='profiles_aspirations_length_check') then
    alter table public.profiles add constraint profiles_aspirations_length_check check (aspirations is null or char_length(aspirations) <= 300);
  end if;
end $$;

revoke all on table public.profiles from anon;
grant select on table public.profiles to authenticated;
revoke update on table public.profiles from authenticated;
grant update (phone, avatar_url, about_me, occupation, profile_class, interests, skills, aspirations)
  on table public.profiles to authenticated;

-- Message rows are immutable after creation. The app only reads and inserts messages.
revoke update on table public.student_direct_messages from authenticated;
drop policy if exists student_direct_messages_update_read on public.student_direct_messages;
