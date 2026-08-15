-- Mind Vector — documenter un sujet sur le fond.
--
-- L'intitulé dit de quoi on parle, la description cadre le désaccord ; il
-- manquait de quoi expliquer le sujet pour de bon — chiffres, contexte, schéma.
-- D'où un texte long (Markdown léger, comme partout ailleurs) et une image,
-- consultables en cliquant l'intitulé du sujet.

alter table public.mv_nodes add column if not exists contenu   text;
alter table public.mv_nodes add column if not exists image_url text;

comment on column public.mv_nodes.contenu is
  'Documentation de fond du sujet, en Markdown léger. Affichée en cliquant l''intitulé.';
comment on column public.mv_nodes.image_url is
  'Illustration du sujet (bucket learn-images), affichée avec le contenu.';
