-- Préalables techniques par offre (remplace le gating flex_seule codé en dur)
-- Valeurs possibles : 'box', 'chauffage_elec', 'solaire', 'batterie'
-- Une offre n'est proposée que si le site remplit TOUTES les conditions cochées.
-- Tableau vide {} = aucun préalable technique.
alter table public.offres
  add column if not exists prealables_techniques text[] not null default '{}';

-- Reprise de l'ancien comportement codé en dur : la flexibilité sans ajout
-- d'objets connectés exigeait une box Comwatt + un usage électrique pilotable
-- (chauffage élec/PAC ou cumulus élec).
update public.offres
  set prealables_techniques = '{box,chauffage_elec}'
  where 'flex_seule' = any(types_offre)
    and (prealables_techniques is null or prealables_techniques = '{}');
