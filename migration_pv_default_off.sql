-- Supprime la valeur PAR DÉFAUT en base de sites.puissance_pv_kwc.
--
-- La colonne portait `DEFAULT 6` : tout site créé sans mentionner la colonne
-- (l'INSERT de l'inscription, handleSignup) naissait avec une CIBLE de 6 kWc de
-- panneaux. MonSiteScreen relit ensuite cette valeur via resolveCartEquipment
-- (branche `sitePv`, considérée comme source de vérité par site), affiche du
-- solaire dans « Ma facture heure par heure », puis l'effet « cible > existant »
-- pose la tuile solaire au panier en 'auto'. Un compte neuf se voyait donc
-- proposer du PV sans l'avoir jamais demandé.
--
-- Le correctif f49ae98 (init de MonSiteScreen alignée sur solar_chosen) n'a jamais
-- pu couvrir ce cas : la valeur ne venait pas de localStorage mais de la base.
--
-- L'absence de PV se note désormais NULL (= « rien de demandé »), et 0 reste une
-- cible explicite (« j'ai tout retiré »).
alter table public.sites alter column puissance_pv_kwc drop default;

-- Rattrapage des sites nés du défaut : puissance cible à 6 alors qu'aucune trace
-- d'un choix réel n'existe (pas de PV existant, pas de batterie renseignée, et
-- parcours d'onboarding jamais répondu sur le solaire).
update public.sites
   set puissance_pv_kwc = null
 where puissance_pv_kwc = 6
   and pv_existant_kwc is null
   and batterie_capacite_kwh is null
   and flex_has_solar is null;
