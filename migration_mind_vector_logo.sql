-- Mind Vector — picto d'une personne morale.
--
-- Comparer sa position à celle de plusieurs organisations n'est lisible que si
-- on reconnaît l'organisation d'un coup d'œil : un petit logo au coin de la
-- case dit en un regard ce qu'une légende oblige à relire. Réservé aux
-- personnes MORALES — une personne physique n'a pas de logo, et en afficher un
-- reviendrait à mettre un visage sur une évaluation nominative.
--
-- Fichier téléversé à la main (choix de Greg) dans le bucket `learn-images`,
-- déjà utilisé par les images Learn : pas de nouveau bucket, pas de nouvelle
-- policy de stockage. On ne garde ici que l'URL publique.
--
-- Écriture : la policy « mv_personnes maj » réserve déjà la modification aux
-- admins pour les fiches sans titulaire, ce qu'est toujours une personne
-- morale. Rien à ouvrir.

alter table public.mv_personnes
  add column if not exists logo_url text;

comment on column public.mv_personnes.logo_url is
  'Mind Vector — picto d''une personne morale (URL publique, bucket learn-images). Null = pas de picto, on retombe sur l''intitulé seul. Sans objet pour une personne physique.';
