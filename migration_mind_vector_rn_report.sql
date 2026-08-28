-- Mind Vector — report de la recherche « Le rassemblement national », et
-- dernier report manuel de cette sorte.
--
-- La recherche Internet écrivait un brouillon dans mv_recherches ; c'est la
-- case « mettre à jour » qui le promouvait en réponse. Sur LFI il avait déjà
-- fallu reporter 19 positions à la main (migration_mind_vector_origine.sql) ;
-- le RN en laissait 36. La corvée revenait donc à chaque profil public — Greg
-- a tranché : la recherche enregistre désormais elle-même, sujet par sujet
-- (voir `appliquerRecherche` dans l'écran). Ce fichier rattrape le seul profil
-- resté en brouillon sous l'ancien comportement.
--
-- Ce qui NE change pas : les 25 sujets sans position restent vides. Sous 40 %
-- de précision la recherche ne classe rien, et ce n'est pas à une passe SQL de
-- décider le contraire.

do $$
declare v_rn   uuid := 'dee30bd6-2da4-4afd-9dc1-e926777373ad';  -- Le rassemblement national
        v_greg uuid := '98628a67-0aa0-41d3-ac92-815894449546';  -- greg@starvolt.fr, qui a lancé la recherche
        n_avant int;
        n_apres int;
begin
  select count(*) into n_avant from public.mv_reponses where personne_id = v_rn;

  insert into public.mv_reponses (personne_id, node_id, auteur_id, pos, origine, updated_at, updated_by)
  select r.personne_id, r.node_id, v_greg, r.pos, 'recherche', now(), 'greg@starvolt.fr'
    from public.mv_recherches r
   where r.personne_id = v_rn and r.pos is not null
  on conflict (personne_id, node_id, auteur_id) do nothing;   -- ne jamais écraser un classement à la main

  -- La case doit dire la vérité sur l'état du profil : un brouillon devenu
  -- réponse s'affiche coché.
  update public.mv_recherches r
     set retenu = true
   where r.personne_id = v_rn and r.pos is not null
     and exists (select 1 from public.mv_reponses q
                  where q.personne_id = r.personne_id and q.node_id = r.node_id
                    and q.auteur_id = v_greg and q.origine = 'recherche');

  select count(*) into n_apres from public.mv_reponses where personne_id = v_rn;
  raise notice 'RN : % réponses avant, % après (+%)', n_avant, n_apres, n_apres - n_avant;
end $$;
