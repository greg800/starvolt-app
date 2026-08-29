-- Fusion des doublons PS / Renaissance.
-- Greg avait déjà créé « Les socialistes » et « Renaissance » (avec leur logo
-- téléversé à la main) pendant que les positions étaient recherchées ; deux
-- fiches jumelles ont été créées en parallèle. On garde CELLES DE GREG — elles
-- sont antérieures et portent les logos — et on y déplace les positions.
begin;

update mv_reponses   set personne_id = '96c92c56-b29c-4789-b29a-ef5ff4ceddc0'
  where personne_id = '3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63';
update mv_recherches set personne_id = '96c92c56-b29c-4789-b29a-ef5ff4ceddc0'
  where personne_id = '3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63';

update mv_reponses   set personne_id = '73fac6a5-b767-4200-9699-bd07656f0f7a'
  where personne_id = '6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41';
update mv_recherches set personne_id = '73fac6a5-b767-4200-9699-bd07656f0f7a'
  where personne_id = '6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41';

-- Les deux fiches en trop sont désormais vides : leur suppression n'emporte
-- rien (le ON DELETE CASCADE n'a plus de ligne à qui s'appliquer).
delete from mv_personnes where id in ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63',
                                      '6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41');

commit;
