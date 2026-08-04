-- Niveau de bricolage (spec §10) — filtre des offres
-- sites.flex_bricolage : niveau 1–5 déclaré par l'utilisateur au questionnaire logement.
--   NULL = pas encore répondu → traité comme 1 côté app (le plus prudent).
-- offres.niveau_min : niveau requis pour se voir proposer l'offre.
--   Défaut 1 = offre clé en main, visible par tous → aucune régression sur l'existant.

alter table public.sites  add column if not exists flex_bricolage smallint;
alter table public.offres add column if not exists niveau_min     smallint not null default 1;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'sites_flex_bricolage_check') then
    alter table public.sites add constraint sites_flex_bricolage_check
      check (flex_bricolage is null or flex_bricolage between 1 and 5);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'offres_niveau_min_check') then
    alter table public.offres add constraint offres_niveau_min_check
      check (niveau_min between 1 and 5);
  end if;
end $$;

comment on column public.sites.flex_bricolage is
  'Niveau de bricolage déclaré (1–5). Filtre les offres : proposée si flex_bricolage >= offres.niveau_min.';
comment on column public.offres.niveau_min is
  'Niveau de bricolage minimum requis (1–5). 1 = clé en main, visible par tous.';
