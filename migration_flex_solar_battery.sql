-- Parcours initial : équipement solaire/batterie existant + autres équipements énergivores
-- (questions posées uniquement aux propriétaires en maison individuelle)

alter table sites
  add column if not exists flex_has_solar       boolean,
  add column if not exists flex_pv_comment       text,
  add column if not exists flex_has_battery      boolean,
  add column if not exists flex_other_equipment  text;

-- Recréer la RPC admin du bilan pour exposer les nouveaux champs + PV/batterie du projet
DROP FUNCTION IF EXISTS public.admin_get_site_bilan_data(uuid);
CREATE OR REPLACE FUNCTION public.admin_get_site_bilan_data(p_site_id uuid)
 RETURNS TABLE(id uuid, user_id uuid, nom text, conso_profil jsonb, conso_annuelle_kwh real, tarif_id uuid, heure_debut_hc1 text, heure_fin_hc1 text, heure_debut_hc2 text, heure_fin_hc2 text, profil_production_id uuid, bilan_ia text, flex_chauffage text, flex_ecs text, flex_surface text, flex_type_logement text, flex_statut text, puissance_souscrite_kva numeric, flex_has_solar boolean, flex_pv_comment text, flex_has_battery boolean, flex_other_equipment text, puissance_pv_kwc numeric, batterie_capacite_kwh numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin if not is_admin() then raise exception 'forbidden'; end if; return query select s.id, s.user_id, s.nom, s.conso_profil, s.conso_annuelle_kwh, s.tarif_id, s.heure_debut_hc1, s.heure_fin_hc1, s.heure_debut_hc2, s.heure_fin_hc2, s.profil_production_id, s.bilan_ia, s.flex_chauffage, s.flex_ecs, s.flex_surface, s.flex_type_logement, s.flex_statut, s.puissance_souscrite_kva, s.flex_has_solar, s.flex_pv_comment, s.flex_has_battery, s.flex_other_equipment, s.puissance_pv_kwc, s.batterie_capacite_kwh from sites s where s.id = p_site_id; end $function$;
