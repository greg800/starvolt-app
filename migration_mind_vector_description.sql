-- Mind Vector — une description facultative du sujet.
--
-- L'intitulé seul (« Production idéale ») ne dit pas ce que le sujet recouvre.
-- Cette description précise ce que le titre évoque : elle sert à l'auteur, et
-- c'est aussi la matière que reçoit le remplissage automatique pour rédiger les
-- 5 positions et leurs titres.

alter table public.mv_nodes add column if not exists description text;

comment on column public.mv_nodes.description is
  'Ce que ce sujet recouvre, en clair. Facultatif. Sert de contexte au remplissage automatique des 5 positions.';
