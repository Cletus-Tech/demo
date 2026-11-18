-- A starter subject catalogue lets the centre publish lessons immediately.
-- Owners can rename, deactivate or extend this list to match their curriculum.

insert into public.subjects(name,description,status)
select v.name,v.description,'active'
from (values
 ('Mathematics','Numeracy, arithmetic, algebra and mathematical reasoning'),
 ('English Language','Reading, writing, grammar, comprehension and communication'),
 ('Basic Science','Foundational scientific knowledge and practical inquiry'),
 ('Basic Technology','Introductory technology, tools and design'),
 ('Social Studies','People, communities, society and civic life'),
 ('Civic Education','Citizenship, rights, responsibilities and values'),
 ('Computer Studies','Digital literacy, computing and information technology'),
 ('Agricultural Science','Agriculture, crops, livestock and food systems'),
 ('Home Economics','Home management, nutrition and family life'),
 ('Physical and Health Education','Physical fitness, movement and personal health'),
 ('Creative Arts','Visual arts, creativity and cultural expression'),
 ('Business Studies','Commerce, entrepreneurship and business fundamentals'),
 ('Biology','Living organisms and life processes'),
 ('Chemistry','Matter, materials and chemical reactions'),
 ('Physics','Energy, forces, motion and physical systems'),
 ('Economics','Resources, markets and economic decision-making'),
 ('Government','Political systems, governance and public institutions'),
 ('Literature in English','Literary texts, language and critical interpretation'),
 ('Geography','Places, environments and human geography'),
 ('Christian Religious Studies','Christian religious knowledge and values'),
 ('Islamic Religious Studies','Islamic religious knowledge and values'),
 ('French','French language and communication')
) as v(name,description)
where not exists (select 1 from public.subjects s where lower(btrim(s.name))=lower(v.name));
