-- Mind Vector — d'où vient une réponse, et report de la recherche « La France
-- Insoumise » dans l'outil principal.
--
-- Une position trouvée sur Internet et une position saisie à la main ne se
-- valent pas : la première s'appuie sur une source datée, qu'il faut pouvoir
-- rouvrir. `origine` porte cette différence ; le détail (extrait, précision,
-- source, date) vit déjà dans mv_recherches, à la même clé.

alter table public.mv_reponses
  add column if not exists origine text;

do $$ begin
  alter table public.mv_reponses
    add constraint mv_reponses_origine_chk check (origine is null or origine in ('recherche'));
exception when duplicate_object then null; end $$;

comment on column public.mv_reponses.origine is
  'null = classement saisi à la main ; ''recherche'' = repris d''une recherche Internet (détail dans mv_recherches).';

-- ── Report de la recherche déjà faite ───────────────────────────────────────
-- Les 19 positions trouvées sur « La France Insoumise » étaient restées à
-- l'état de brouillon : la case « mettre à jour » n'avait pas été cochée. On
-- les reporte au nom de Grégory, qui a lancé la recherche.
--
-- Borné à CE profil, à dessein : ce fichier est rejouable, et une passe qui
-- reporterait toute recherche concluante viderait de son sens la case à cocher
-- — le passage du brouillon à la réponse doit rester un geste.
do $$
declare v_lfi  uuid := '477b88ea-e1ab-4c90-b37c-2520b0ddc5e5';
        v_greg uuid := '98628a67-0aa0-41d3-ac92-815894449546';
begin
  insert into public.mv_reponses (personne_id, node_id, auteur_id, pos, origine, updated_at, updated_by)
  select r.personne_id, r.node_id, v_greg, r.pos, 'recherche', now(), 'greg@starvolt.fr'
    from public.mv_recherches r
   where r.personne_id = v_lfi and r.pos is not null
  on conflict (personne_id, node_id, auteur_id) do nothing;   -- ne jamais écraser un classement à la main

  update public.mv_recherches r
     set retenu = true
   where r.personne_id = v_lfi and r.pos is not null
     and exists (select 1 from public.mv_reponses q
                  where q.personne_id = r.personne_id and q.node_id = r.node_id
                    and q.auteur_id = v_greg and q.origine = 'recherche');
end $$;
