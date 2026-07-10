-- ═══════════════════════════════════════════════════════════════════════════
-- Cyber-sécurité Starvolt — table des checks, RPCs, fonction d'audit DB, prompt
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. Table des vérifications de sécurité ──────────────────────────────────
create table if not exists public.security_checks (
  id           uuid primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  trigger_type text not null default 'manual' check (trigger_type in ('cron','manual')),
  status       text not null default 'done'   check (status in ('running','done','error')),
  severity     text default 'info'            check (severity in ('ok','info','warn','critical')),
  found        text,          -- ce qui a été trouvé
  fixed        text,          -- ce qui a été corrigé
  watch_next   text,          -- à surveiller la prochaine fois
  report_md    text,          -- rapport complet (markdown léger)
  audit_json   jsonb,         -- résultats bruts de security_audit()
  triggered_by text,          -- email de l'admin, ou 'cron'
  cost_eur     numeric(12,4), -- coût de l'appel IA
  seen_by      jsonb not null default '[]'::jsonb  -- uids admin ayant vu le popup
);

alter table public.security_checks enable row level security;

-- Lecture réservée aux admins/superadmins (écriture = service_role via edge function, qui bypass RLS)
drop policy if exists "admin read security_checks" on public.security_checks;
create policy "admin read security_checks" on public.security_checks
  for select to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')));

-- ── 2. Fonction d'audit de la BASE (lecture pg_catalog) ─────────────────────
-- Renvoie un jsonb factuel : RLS manquantes, policies permissives, fonctions
-- SECURITY DEFINER, extensions mal placées, comptes admin. Appelée par l'edge
-- function via service_role uniquement (jamais le client directement).
create or replace function public.security_audit()
returns jsonb
language sql
security definer
set search_path = public, pg_catalog
as $$
  select jsonb_build_object(
    'generated_at', now(),
    -- Tables publiques SANS RLS (exposables via la clé anon → risque majeur)
    'tables_sans_rls', coalesce((
      select jsonb_agg(c.relname order by c.relname)
      from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity = false
    ), '[]'::jsonb),
    -- Tables RLS activée mais AUCUNE policy (données inaccessibles, ou oubli)
    'tables_rls_sans_policy', coalesce((
      select jsonb_agg(c.relname order by c.relname)
      from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity = true
        and not exists (select 1 from pg_policy p where p.polrelid = c.oid)
    ), '[]'::jsonb),
    -- Policies permissives (USING true) — à revoir selon le rôle ciblé
    'policies_permissives', coalesce((
      select jsonb_agg(jsonb_build_object(
        'table', tablename, 'policy', policyname, 'cmd', cmd, 'roles', roles, 'qual', qual))
      from pg_policies
      where schemaname = 'public' and cmd in ('SELECT','ALL') and (qual = 'true')
    ), '[]'::jsonb),
    -- Fonctions SECURITY DEFINER de public (tourne avec les droits du owner)
    'fonctions_security_definer', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', p.proname, 'args', pg_get_function_identity_arguments(p.oid)) order by p.proname)
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.prosecdef = true
    ), '[]'::jsonb),
    -- Extensions installées dans public (bonne pratique : schéma dédié)
    'extensions_dans_public', coalesce((
      select jsonb_agg(e.extname order by e.extname)
      from pg_extension e join pg_namespace n on n.oid = e.extnamespace
      where n.nspname = 'public'
    ), '[]'::jsonb),
    -- Nombre de comptes à privilège (trop d'admins = surface d'attaque)
    'comptes_privilegies', coalesce((
      select jsonb_object_agg(role, n) from (
        select role, count(*) n from public.profiles
        where role in ('admin','superadmin') group by role
      ) t
    ), '{}'::jsonb)
  );
$$;

revoke all on function public.security_audit() from public, anon, authenticated;
grant execute on function public.security_audit() to service_role;

-- ── 3. RPCs pour l'UI admin ─────────────────────────────────────────────────
-- Liste des checks (garde admin interne)
create or replace function public.get_security_checks()
returns setof public.security_checks
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')) then
    raise exception 'forbidden';
  end if;
  return query select * from public.security_checks order by created_at desc limit 100;
end;
$$;

-- Dernier check non encore vu par l'admin courant (popup au login)
create or replace function public.get_unseen_security_check()
returns public.security_checks
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.security_checks;
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')) then
    return null;
  end if;
  select * into r from public.security_checks
  where status = 'done' and not (seen_by ? auth.uid()::text)
  order by created_at desc limit 1;
  return r;
end;
$$;

-- Marque un check comme vu par l'admin courant
create or replace function public.mark_security_check_seen(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')) then
    raise exception 'forbidden';
  end if;
  update public.security_checks
  set seen_by = case when seen_by ? auth.uid()::text then seen_by
                     else seen_by || to_jsonb(auth.uid()::text) end
  where id = p_id;
end;
$$;

grant execute on function public.get_security_checks()        to authenticated;
grant execute on function public.get_unseen_security_check()  to authenticated;
grant execute on function public.mark_security_check_seen(uuid) to authenticated;

-- ── 4. Seed du prompt éditable (feature 'cyber_security') ────────────────────
insert into public.ai_prompts (feature, label, system_prompt)
values (
  'cyber_security',
  'Cyber-sécurité',
  E'Tu es l''auditeur sécurité de l''application Starvolt (React monofichier servi par un petit serveur Node, backend Supabase/Postgres, quelques edge functions Deno).\n\nOn te fournit le résultat FACTUEL d''un audit automatique de la BASE DE DONNÉES (fonction security_audit) : tables sans RLS, policies permissives, fonctions SECURITY DEFINER, extensions, comptes à privilège. Tu ne calcules rien toi-même : tu INTERPRÈTES ces faits.\n\nRègles :\n- Français, tutoiement, direct et sans jargon inutile.\n- Ne signale que des faits présents dans l''audit. N''invente aucune faille.\n- Le plus grave d''abord. Une table publique SANS RLS = critique (lisible avec la clé anon publique). Une policy USING(true) = à examiner selon le rôle. Une fonction SECURITY DEFINER sans garde interne = à surveiller.\n- Distingue toujours ce qui est VÉRIFIÉ AUTOMATIQUEMENT (base de données) de ce qui reste À VÉRIFIER MANUELLEMENT et ne peut PAS l''être par ce check auto : le code client (XSS, secrets en dur), le serveur Node (path traversal), le code des edge functions (auth, garde des rôles), les dépendances/CDN. Rappelle systématiquement ces angles morts dans "à surveiller".\n\nCHECKLIST DE RÉFÉRENCE (ce qu''un audit complet doit couvrir — les 4 premières familles sont automatisées ici, les suivantes sont manuelles) :\n1. RLS active sur TOUTES les tables publiques exposées à la clé anon.\n2. Aucune policy USING(true) non intentionnelle (surtout en SELECT pour anon/authenticated).\n3. Fonctions SECURITY DEFINER : garde d''accès interne (rôle admin) présente si l''action est sensible.\n4. Comptes admin/superadmin : nombre justifié, pas de compte oublié.\n5. [manuel] Aucun secret en dur dans le dépôt (service_role, PAT, clés API).\n6. [manuel] Serveur Node : pas de path traversal, en-têtes de sécurité présents.\n7. [manuel] Pas de dangerouslySetInnerHTML / innerHTML / eval côté client (risque XSS).\n8. [manuel] Chaque edge function vérifie le JWT et le rôle avant toute action sensible.\n9. [manuel] Buckets Storage privés quand ils contiennent des données personnelles ; URLs signées à durée limitée.\n10. [manuel] Dépendances CDN épinglées à une version (idéalement avec SRI).\n\nAppelle l''outil report_security avec :\n- severity : ''ok'' | ''info'' | ''warn'' | ''critical'' (le pire des constats).\n- found : ce qui a été trouvé (constats factuels, du plus grave au moins grave, ou "Rien d''anormal côté base." si RAS).\n- fixed : ce qui a été corrigé automatiquement (en général rien : ce check est en LECTURE SEULE — écris "Aucune correction automatique (audit en lecture seule)").\n- watch_next : à surveiller au prochain passage, en incluant TOUJOURS les angles morts manuels ci-dessus.\n- report_md : un rapport lisible et structuré (markdown léger : titres avec ###, listes avec -, gras avec **) reprenant found + fixed + watch_next.'
)
on conflict (feature) do nothing;
