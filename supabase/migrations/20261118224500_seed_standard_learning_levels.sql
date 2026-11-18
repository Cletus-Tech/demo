-- Provide the standard Nigerian learning levels so the owner can create
-- programmes immediately without building a formal school session structure.

insert into public.classes(name,level,status)
select v.name,v.level,'active'
from (values
 ('Primary 1','Primary 1'),
 ('Primary 2','Primary 2'),
 ('Primary 3','Primary 3'),
 ('Primary 4','Primary 4'),
 ('Primary 5','Primary 5'),
 ('Primary 6','Primary 6'),
 ('JSS 1','JSS 1'),
 ('JSS 2','JSS 2'),
 ('JSS 3','JSS 3'),
 ('SS 1','SS 1'),
 ('SS 2','SS 2'),
 ('SS 3','SS 3')
) as v(name,level)
where not exists (
  select 1 from public.classes c where lower(btrim(c.name))=lower(v.name)
);
