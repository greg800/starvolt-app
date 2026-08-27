-- Saisie manuelle de l'équipement déjà installé chez le client.
--
-- Le parcours ne pose pas toujours toutes les questions (constat 2026-08-27 :
-- en repassant le parcours pour retirer PV et batterie, la question de la box
-- n'est pas reposée — la box restait donc cochée sans moyen de l'enlever).
-- La tuile « Déjà installé chez le client » devient éditable au crayon, ce qui
-- suppose de pouvoir stocker une capacité thermique saisie à la main.
--
-- Jusqu'ici la capacité thermique existante était UNIQUEMENT déduite de
-- flex_chauffage / flex_ecs / flex_surface (fonction thermalPotentialKwh).
-- Cette colonne, quand elle est renseignée, prend le pas sur la déduction.
-- NULL = comportement inchangé (on déduit).
alter table public.sites
  add column if not exists stockage_thermique_existant_kwh numeric;

comment on column public.sites.stockage_thermique_existant_kwh is
  'Capacité de stockage thermique déjà installée (kWh/cycle jour), saisie à la main. NULL = déduite de flex_chauffage/flex_ecs/flex_surface.';
