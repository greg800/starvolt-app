-- Calendrier de jours attaché à une grille multi-périodes.
-- Une règle de période peut désormais filtrer sur deux axes de plus : le jour de
-- la semaine (tarifs week-end) et la couleur du jour (Tempo). La couleur ne peut
-- pas se déduire de la date — elle vient d'un classement des jours par coût spot,
-- stocké ici une fois pour toutes plutôt que recalculé à chaque chiffrage.
--
-- Format : {"type":"tempo","source":"spot","annee_ref":2024,
--           "jours":"BBWR…" (366 codes, 1 par jour : B bleu, W blanc, R rouge),
--           "compte":{"rouge":22,"blanc":43,"bleu":301},"genere_le":"…"}
--
-- Les grilles existantes restent à NULL : sans calendrier, une règle sans
-- couleur s'applique comme avant.

alter table public.tarifs_electricite
  add column if not exists calendrier jsonb;

comment on column public.tarifs_electricite.calendrier is
  'Couleur de chaque jour de l''année type (366 codes). Alimenté par l''assistant Tempo à partir des prix spot. NULL = grille sans notion de couleur de jour.';
