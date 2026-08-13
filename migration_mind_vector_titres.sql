-- Mind Vector — un titre par position, et non plus seulement pour les extrêmes.
--
-- Jusqu'ici seules les positions 1 et 5 étaient nommables, via mv_nodes.pole_gauche
-- et pole_droit ; les trois du milieu affichaient « nuancé / équilibre / nuancé »
-- en dur. Le titre descend donc au bon endroit : sur la ligne (nœud, position),
-- là où vit déjà son contenu. Les cinq se nomment maintenant de la même façon.

alter table public.mv_positions add column if not exists titre text;

-- Reprise des pôles déjà saisis, quand la ligne de position existe.
update public.mv_positions p
   set titre = n.pole_gauche
  from public.mv_nodes n
 where p.node_id = n.id and p.pos = 1
   and p.titre is null and nullif(btrim(n.pole_gauche), '') is not null;

update public.mv_positions p
   set titre = n.pole_droit
  from public.mv_nodes n
 where p.node_id = n.id and p.pos = 5
   and p.titre is null and nullif(btrim(n.pole_droit), '') is not null;

-- Un pôle pouvait être nommé sans qu'aucun texte n'ait encore été écrit : dans ce
-- cas il n'existe pas de ligne mv_positions, on la crée pour ne rien perdre.
insert into public.mv_positions (node_id, pos, content, titre)
select n.id, 1, '', n.pole_gauche
  from public.mv_nodes n
 where nullif(btrim(n.pole_gauche), '') is not null
   and not exists (select 1 from public.mv_positions p where p.node_id = n.id and p.pos = 1);

insert into public.mv_positions (node_id, pos, content, titre)
select n.id, 5, '', n.pole_droit
  from public.mv_nodes n
 where nullif(btrim(n.pole_droit), '') is not null
   and not exists (select 1 from public.mv_positions p where p.node_id = n.id and p.pos = 5);

comment on column public.mv_positions.titre is
  'Nom de cette position pour ce sujet (ex. « centralisé »). Vide = libellé par défaut du rang (un extrême, nuancé, équilibre…).';
comment on column public.mv_nodes.pole_gauche is
  'HISTORIQUE — repris dans mv_positions.titre (pos 1) le 2026-08-13, plus lu par l''application.';
comment on column public.mv_nodes.pole_droit is
  'HISTORIQUE — repris dans mv_positions.titre (pos 5) le 2026-08-13, plus lu par l''application.';
