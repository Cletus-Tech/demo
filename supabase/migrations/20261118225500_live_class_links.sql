-- Store the virtual classroom link alongside each published lesson.
-- The link is only visible to learners whose programme access is approved.

alter table public.lessons
  add column if not exists live_class_url text;
