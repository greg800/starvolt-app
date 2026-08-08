-- Couverture des données ENEDIS dans le bilan IA.
-- Un contrat ENEDIS de moins d'un an ne remonte pas 12 mois : les mois jamais
-- mesurés sont reconstruits par extrapolation saisonnière à la collecte
-- (edge switchgrid-v0, completeYear) et décrits dans sites.conso_gaps.
-- buildBilanFacts lit conso_gaps / conso_coverage pour dire à l'IA ce qui est
-- mesuré et ce qui est estimé — sans ça, elle félicite un foyer pour une
-- « faible conso » qui n'est qu'un emménagement récent.
-- L'aperçu admin passe par cette RPC : sans ces deux colonnes, la section
-- « Données ENEDIS » du tableau resterait vide.

drop function if exists public.admin_get_site_bilan_data(uuid);

create or replace function public.admin_get_site_bilan_data(p_site_id uuid)
returns table(
  id uuid, user_id uuid, nom text, conso_profil jsonb, conso_annuelle_kwh real,
  conso_gaps jsonb, conso_coverage numeric,
  tarif_id uuid, heure_debut_hc1 text, heure_fin_hc1 text, heure_debut_hc2 text,
  heure_fin_hc2 text, profil_production_id uuid, bilan_ia text, bilan_ia_facts jsonb,
  code_postal text, flex_chauffage text, flex_ecs text, flex_surface text,
  flex_type_logement text, flex_statut text, puissance_souscrite_kva numeric,
  flex_has_solar boolean, flex_pv_comment text, flex_has_battery boolean,
  flex_other_equipment text, puissance_pv_kwc numeric, batterie_capacite_kwh numeric,
  pv_existant_kwc numeric, batterie_existante_kwh numeric
)
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not is_admin() then raise exception 'forbidden'; end if;
  return query select
    s.id, s.user_id, s.nom, s.conso_profil, s.conso_annuelle_kwh,
    s.conso_gaps, s.conso_coverage,
    s.tarif_id, s.heure_debut_hc1, s.heure_fin_hc1, s.heure_debut_hc2,
    s.heure_fin_hc2, s.profil_production_id, s.bilan_ia, s.bilan_ia_facts,
    s.code_postal, s.flex_chauffage, s.flex_ecs, s.flex_surface,
    s.flex_type_logement, s.flex_statut, s.puissance_souscrite_kva,
    s.flex_has_solar, s.flex_pv_comment, s.flex_has_battery,
    s.flex_other_equipment, s.puissance_pv_kwc, s.batterie_capacite_kwh,
    s.pv_existant_kwc, s.batterie_existante_kwh
  from sites s where s.id = p_site_id;
end
$function$;
