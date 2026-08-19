-- Mind Vector — parcours par défaut
--
-- Un administrateur décide, dans « Paramètres Mind Vector », quelles branches
-- de l'arbre sont proposées d'office. À la création de sa fiche, un nouveau
-- compte hérite de ce périmètre : les branches décochées ici partent dans ses
-- `exclusions`. Ensuite sa fiche vit sa vie — il peut rouvrir n'importe quelle
-- branche cachée depuis son propre menu, et son choix tient pour toutes les
-- sessions suivantes.
--
-- On ne stocke donc pas un « parcours par défaut » à part : c'est une graine,
-- lue une seule fois, à la naissance de la fiche.

alter table public.mv_nodes
  add column if not exists visible_defaut boolean not null default true;

comment on column public.mv_nodes.visible_defaut is
  'Mind Vector — branche proposée d''office aux nouveaux comptes. Décochée, elle part dans les exclusions de la fiche à sa création ; chacun peut la rouvrir ensuite.';
