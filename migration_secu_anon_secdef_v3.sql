-- Audit sécurité — C2 : fermer les fonctions SECURITY DEFINER au rôle anon
--
-- Remplace migration_revoke_anon_secdef.sql (v1, énumération manuelle + REVOKE
-- FROM public : 2 warnings corrigés sur 101) et sa v2 (bon balayage, mais sans
-- le prérequis ci-dessous).
--
-- Le linter Supabase teste l'accès effectif du rôle `anon` : un GRANT explicite
-- à anon survit à un REVOKE FROM public. On révoque donc anon nommément, et on
-- balaie pg_proc au lieu d'énumérer à la main (la base contient des fonctions
-- créées dans le dashboard, sans fichier de migration local).

-- ── 1. Prérequis ────────────────────────────────────────────────────────────
-- Ces deux policies sont ouvertes au rôle `public` (donc évaluées pour anon) et
-- appellent is_admin(). Une fois EXECUTE révoqué à anon, une requête anonyme sur
-- ces tables renverrait « permission denied for function is_admin » au lieu de
-- 0 ligne. On les restreint à `authenticated` : anon ne peut de toute façon
-- jamais être admin.
alter policy "Admin seulement" on public.offres to authenticated;
alter policy "Admins can read all events" on public.user_events to authenticated;

-- ── 2. Durcissement ─────────────────────────────────────────────────────────
-- Ordre important : on accorde EXECUTE à authenticated *avant* de révoquer.
-- Sans ce grant préalable, les fonctions dont l'accès des utilisateurs connectés
-- reposait sur le GRANT implicite à PUBLIC deviendraient inaccessibles à tous.
--
-- Les fonctions qu'anon ne peut déjà plus exécuter ne sont pas touchées : le
-- durcissement existant de factures_a_purger (service_role seul) est préservé.
--
-- Exceptions laissées ouvertes à anon :
--   log_app_error    — journal des erreurs JS émises avant authentification
--   get_default_role — appelée pendant l'inscription, sans session
do $$
declare
  f record;
  keep constant text[] := array['log_app_error', 'get_default_role'];
  n int := 0;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace ns on ns.oid = p.pronamespace
    where ns.nspname = 'public'
      and p.prosecdef
      and p.proname <> all(keep)
      and has_function_privilege('anon', p.oid, 'EXECUTE')
  loop
    execute format('grant execute on function %s to authenticated', f.sig);
    execute format('revoke execute on function %s from anon, public', f.sig);
    n := n + 1;
  end loop;
  raise notice 'Fonctions durcies : %', n;
end $$;

-- Contrôle : doit renvoyer exactement les 2 exceptions ci-dessus.
select p.oid::regprocedure::text as encore_ouverte_a_anon
from pg_proc p
join pg_namespace ns on ns.oid = p.pronamespace
where ns.nspname = 'public'
  and p.prosecdef
  and has_function_privilege('anon', p.oid, 'EXECUTE')
order by 1;
