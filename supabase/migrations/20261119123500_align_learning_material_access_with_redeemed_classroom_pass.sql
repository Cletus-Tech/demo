alter policy materials_read_published on public.learning_materials
using (
  exists (
    select 1
    from public.lessons l
    where l.id = learning_materials.lesson_id
      and l.is_published = true
      and (
        private.has_permission('academics.manage')
        or exists (
          select 1
          from public.learning_access_requests r
          join public.learning_programmes p on p.id = r.programme_id
          join public.classroom_access_passes cap on cap.request_id = r.id
          where r.user_id = (select auth.uid())
            and r.status = 'approved'
            and p.class_id = l.class_id
            and cap.redeemed_at is not null
            and cap.revoked_at is null
        )
        or exists (
          select 1
          from public.class_tutors ct
          join public.tutors t on t.id = ct.tutor_id
          where ct.class_id = l.class_id
            and t.user_id = (select auth.uid())
            and t.status = 'active'
        )
      )
  )
);
