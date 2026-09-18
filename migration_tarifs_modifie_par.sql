-- Provenance d'une grille : l'import PDF et l'OCR de facture signent déjà
-- (verifie_par / import_source), mais une saisie ou une retouche à la main
-- ne laissait que last_modified, sans auteur. Le client renseigne désormais
-- modifie_par (e-mail de l'admin) à chaque enregistrement manuel.
alter table public.tarifs_electricite
  add column if not exists modifie_par text;
comment on column public.tarifs_electricite.modifie_par is
  'E-mail de l''admin ayant fait le dernier enregistrement manuel (formulaire). Null si la ligne n''a jamais été touchée à la main.';
