create index if not exists staff_room_messages_sender_id_idx on public.staff_room_messages(sender_id);
create index if not exists staff_members_created_by_idx on public.staff_members(created_by);
create index if not exists tutor_applications_reviewed_by_idx on public.tutor_applications(reviewed_by);