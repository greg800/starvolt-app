-- ════════════════════════════════════════════════════════════════════════════
-- Capture du contrat actuel : recherche d'offre + facture OCR
-- Décision Greg (2026-08-04) : UNE SEULE grille de tarifs (tarifs_electricite).
-- Elle est alimentée par l'OCR seulement après validation admin OU corroboration
-- par 2 factures concordantes.
--
-- Traduction : un tarif lu sur une facture entre dans la table AVEC
-- statut = 'brouillon'. Un brouillon sert UNIQUEMENT à calculer la facture de
-- l'utilisateur qui l'a déposé (son site pointe dessus) ; il n'apparaît dans
-- AUCUN catalogue ni comparatif tant qu'il n'est pas promu 'verifie'. On garde
-- ainsi une seule table et tous les calculs existants (lookup par tarif_id)
-- fonctionnent sans modification.
-- ════════════════════════════════════════════════════════════════════════════

-- ── 1. Grille unique : statut + traçabilité ─────────────────────────────────
alter table public.tarifs_electricite
  add column if not exists statut        text not null default 'verifie',
  add column if not exists source        text not null default 'manuel',
  add column if not exists fournisseur   text,
  add column if not exists puissance_kva smallint,
  add column if not exists verifie_le    timestamptz,
  add column if not exists verifie_par   text;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'tarifs_statut_check') then
    alter table public.tarifs_electricite add constraint tarifs_statut_check
      check (statut in ('verifie','brouillon'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'tarifs_source_check') then
    alter table public.tarifs_electricite add constraint tarifs_source_check
      check (source in ('manuel','ocr'));
  end if;
end $$;

-- Le catalogue public est petit : un index partiel suffit largement.
create index if not exists tarifs_statut_idx on public.tarifs_electricite (statut);

-- ── 2. Factures déposées ────────────────────────────────────────────────────
create table if not exists public.factures (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  site_id         uuid references public.sites(id) on delete set null,
  storage_key     text not null,
  mime            text,
  taille_octets   integer,
  -- Consentement explicite et tracé (RGPD) : sans lui, pas d'upload possible.
  consentement_at timestamptz not null default now(),
  uploaded_at     timestamptz not null default now(),
  -- Rétention 3 mois puis purge du fichier. Les données structurées de
  -- l'extraction survivent : le recalcul reste possible après la purge.
  retention_until timestamptz not null default (now() + interval '3 months'),
  purgee_at       timestamptz,
  ocr_statut      text not null default 'en_attente',
  ocr_erreur      text
);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'factures_ocr_statut_check') then
    alter table public.factures add constraint factures_ocr_statut_check
      check (ocr_statut in ('en_attente','ok','echec'));
  end if;
end $$;

create index if not exists factures_user_idx      on public.factures (user_id);
create index if not exists factures_retention_idx on public.factures (retention_until) where purgee_at is null;

-- ── 3. Extractions (données structurées lues sur la facture) ────────────────
-- Cette table EST la file de travail admin (§8 de la spec) : un événement
-- machine structuré, distinct du feedback humain (app_feedback).
create table if not exists public.factures_extractions (
  id               uuid primary key default gen_random_uuid(),
  facture_id       uuid not null references public.factures(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  site_id          uuid references public.sites(id) on delete set null,
  fournisseur      text,
  offre_nom        text,
  type_tarif       text,
  pdl              text,
  puissance_kva    smallint,
  conso_hp_kwh     numeric,
  conso_hc_kwh     numeric,
  conso_totale_kwh numeric,
  abo_mensuel      numeric,
  prix_base        numeric,
  prix_hp          numeric,
  prix_hc          numeric,
  -- {offre_nom: 0-1, prix: 0-1, pdl: 0-1} — c'est la confiance sur les PRIX qui
  -- décide si on calcule sur la facture ou si on se replie (spec §4).
  confiance        jsonb,
  -- Clé normalisée « fournisseur|offre » : deux extractions de clients
  -- différents qui la partagent (prix cohérents) déclenchent la corroboration.
  cle_offre        text,
  tarif_id         uuid references public.tarifs_electricite(id) on delete set null,
  statut           text not null default 'brouillon',
  created_at       timestamptz not null default now(),
  resolu_le        timestamptz,
  resolu_par       text
);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'extractions_statut_check') then
    alter table public.factures_extractions add constraint extractions_statut_check
      check (statut in ('brouillon','promu','rejete'));
  end if;
end $$;

create index if not exists extractions_cle_idx    on public.factures_extractions (cle_offre) where statut = 'brouillon';
create index if not exists extractions_statut_idx on public.factures_extractions (statut);
create index if not exists extractions_user_idx   on public.factures_extractions (user_id);

-- ── 4. Notifications de recalcul (lien signé de l'email) ────────────────────
create table if not exists public.recalcul_notifs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  site_id    uuid references public.sites(id) on delete cascade,
  tarif_id   uuid references public.tarifs_electricite(id) on delete cascade,
  token      text not null unique,
  expire_le  timestamptz not null default (now() + interval '30 days'),
  envoye_le  timestamptz,
  clique_le  timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists recalcul_token_idx on public.recalcul_notifs (token);

-- ── 5. RLS ──────────────────────────────────────────────────────────────────
alter table public.factures             enable row level security;
alter table public.factures_extractions enable row level security;
alter table public.recalcul_notifs      enable row level security;

-- Factures : l'utilisateur dépose et relit les siennes. Jamais d'update/delete
-- côté client (la purge est faite par le cron via service_role).
drop policy if exists "facture insert own" on public.factures;
create policy "facture insert own" on public.factures
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "facture select own" on public.factures;
create policy "facture select own" on public.factures
  for select to authenticated using (auth.uid() = user_id);

-- Extractions : lecture seule de ses propres extractions. L'écriture est
-- exclusivement le fait de l'edge function (service_role, bypass RLS).
drop policy if exists "extraction select own" on public.factures_extractions;
create policy "extraction select own" on public.factures_extractions
  for select to authenticated using (auth.uid() = user_id);

-- recalcul_notifs : aucune policy → service_role uniquement. Le token est
-- vérifié côté edge function, jamais lu par le navigateur.

-- ── 6. Purge automatique des PDF à 3 mois ───────────────────────────────────
-- Marque les factures à purger. La suppression du fichier dans le bucket est
-- faite par l'edge function (l'API Storage refuse les DELETE en SQL direct).
create or replace function public.factures_a_purger()
returns setof public.factures
language sql security definer set search_path = public as $$
  select * from public.factures
  where purgee_at is null and retention_until < now();
$$;
revoke all on function public.factures_a_purger() from public, anon, authenticated;

comment on table public.factures is
  'Factures déposées par les clients. PDF purgé à 3 mois (retention_until) ; les données structurées survivent dans factures_extractions.';
comment on table public.factures_extractions is
  'Données lues sur la facture + file de validation admin. statut brouillon = à valider, promu = entré dans la grille.';
comment on column public.tarifs_electricite.statut is
  'verifie = catalogue public (comparatifs, recherche). brouillon = lu sur une facture, visible du seul déposant, en attente de validation ou de corroboration.';
