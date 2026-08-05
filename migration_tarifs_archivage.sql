-- Archivage des tarifs : un tarif remplacé n'est pas supprimé, il est daté.
-- Import PDF du comparateur Énergie-Info : une offre déjà connue (même
-- fournisseur + même nom) voit son ancienne grille clôturée et une nouvelle
-- ligne prendre le relais. On garde l'historique : un devis fait il y a six
-- mois doit rester explicable.

alter table public.tarifs_electricite
  add column if not exists actif             boolean not null default true,
  add column if not exists date_debut        date,
  add column if not exists date_fin          date,
  add column if not exists remplace_tarif_id uuid references public.tarifs_electricite(id) on delete set null,
  add column if not exists import_source     text;   -- ex : 'pdf:mne-offres (fixe).pdf'

-- Les tarifs existants sont en service depuis leur création, sans date de fin.
update public.tarifs_electricite
   set date_debut = coalesce(date_debut, created_at::date)
 where date_debut is null;

-- Un tarif archivé ne doit plus jamais entrer dans un comparatif : le filtre
-- se fait côté application (tarifsVisibles), l'index sert les requêtes de liste.
create index if not exists tarifs_actif_idx on public.tarifs_electricite (actif) where actif;

comment on column public.tarifs_electricite.actif is
  'false = grille clôturée, remplacée par une version plus récente. Jamais proposée ni comparée ; conservée pour expliquer un chiffrage passé.';
comment on column public.tarifs_electricite.date_debut is 'Date de mise en service de cette grille.';
comment on column public.tarifs_electricite.date_fin is 'Date de fin de validité (renseignée à l''archivage).';
comment on column public.tarifs_electricite.remplace_tarif_id is 'Tarif que cette ligne remplace (chaîne d''historique).';
