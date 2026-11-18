create index if not exists class_tutors_tutor_class_subject_idx
  on public.class_tutors (tutor_id,class_id,subject_id);
create index if not exists assignments_tutor_class_subject_idx
  on public.assignments (tutor_id,class_id,subject_id);
