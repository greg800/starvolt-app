-- Fix P1 : Auth RLS Initialization Plan — 73 warnings Supabase Performance Advisor.
-- Remplace `auth.uid()` par `(select auth.uid())` dans les policies RLS pour que
-- PostgreSQL évalue la fonction une seule fois par requête (init plan) plutôt
-- qu'une fois par ligne (re-evaluation).
--
-- Tables couvertes ici : celles dont les policies sont trackées localement.
-- Les tables sans migration locale (profiles, sites, tarifs_electricite,
-- switchgrid_requests, user_events, user_learn_progress, app_feedback,
-- security_checks, filtres_config) ont leurs policies définies dans le dashboard
-- Supabase — appliquer le même pattern via l'éditeur SQL ou table editor.

-- ── factures ────────────────────────────────────────────────────────────────
drop policy if exists "facture insert own" on public.factures;
create policy "facture insert own" on public.factures
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "facture select own" on public.factures;
create policy "facture select own" on public.factures
  for select to authenticated using ((select auth.uid()) = user_id);

-- ── factures_extractions ────────────────────────────────────────────────────
drop policy if exists "extraction select own" on public.factures_extractions;
create policy "extraction select own" on public.factures_extractions
  for select to authenticated using ((select auth.uid()) = user_id);

-- ── mv_portraits ────────────────────────────────────────────────────────────
drop policy if exists "mv_portraits lecture" on public.mv_portraits;
create policy "mv_portraits lecture" on public.mv_portraits
  for select to authenticated using (auteur_id = (select auth.uid()));

drop policy if exists "mv_portraits ecriture" on public.mv_portraits;
create policy "mv_portraits ecriture" on public.mv_portraits
  for all to authenticated
  using      (auteur_id = (select auth.uid()))
  with check (auteur_id = (select auth.uid()));

-- ── mv_personnes ────────────────────────────────────────────────────────────
drop policy if exists "mv_personnes fiche perso maj" on public.mv_personnes;
create policy "mv_personnes fiche perso maj" on public.mv_personnes
  for update to authenticated
  using      (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ── mv_acces ────────────────────────────────────────────────────────────────
drop policy if exists "mv_acces lecture" on public.mv_acces;
create policy "mv_acces lecture" on public.mv_acces
  for select to authenticated using (
    evaluateur_id = (select auth.uid())
    or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = (select auth.uid()))
    or exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'superadmin')
  );

drop policy if exists "mv_acces ecriture" on public.mv_acces;
create policy "mv_acces ecriture" on public.mv_acces
  for all to authenticated
  using (
    exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = (select auth.uid()))
    or exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'superadmin')
  )
  with check (
    exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = (select auth.uid()))
    or exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'superadmin')
  );

-- ── mv_reponses ──────────────────────────────────────────────────────────────
drop policy if exists "mv_reponses ecriture" on public.mv_reponses;
create policy "mv_reponses ecriture" on public.mv_reponses
  for all to authenticated
  using (
    auteur_id = (select auth.uid())
    and (
      exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('admin','superadmin'))
      or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = (select auth.uid()))
      or exists (select 1 from public.mv_acces a where a.personne_id = mv_reponses.personne_id and a.evaluateur_id = (select auth.uid()))
    )
  )
  with check (
    auteur_id = (select auth.uid())
    and (
      exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('admin','superadmin'))
      or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = (select auth.uid()))
      or exists (select 1 from public.mv_acces a where a.personne_id = mv_reponses.personne_id and a.evaluateur_id = (select auth.uid()))
    )
  );
