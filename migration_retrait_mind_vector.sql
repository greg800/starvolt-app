-- ═══════════════════════════════════════════════════════════════════════════
--  Starvolt — retrait du module Mind Vector (parti sur socrate.me)
--
--  À jouer UNIQUEMENT après :
--    1. export des données vers le projet Supabase de Socrate
--       (python3 .claude/data-migrate.py export/import/verify dans socrate-me) ;
--    2. vérification de socrate.me en production par Greg.
--  Une sauvegarde SQL des tables est conservée dans socrate-me/supabase/export/.
--
--  Détruit : les 8 tables mv_*, les fonctions et déclencheurs qui n'existent
--  que pour elles, les 4 prompts IA, la clé de permission menus.mind_vector,
--  et les lignes de coût IA de la fonctionnalité.
-- ═══════════════════════════════════════════════════════════════════════════
begin;

-- Tables (cascade emporte policies, index, contraintes et déclencheurs)
drop table if exists public.mv_recherches cascade;
drop table if exists public.mv_portraits  cascade;
drop table if exists public.mv_precisions cascade;
drop table if exists public.mv_acces      cascade;
drop table if exists public.mv_reponses   cascade;
drop table if exists public.mv_personnes  cascade;
drop table if exists public.mv_positions  cascade;
drop table if exists public.mv_nodes      cascade;

-- Fonctions propres au module (signatures telles que créées par les migrations)
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure::text as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname like 'mv\_%'
  loop
    execute 'drop function if exists ' || r.sig || ' cascade';
  end loop;
end $$;

-- Prompts et coûts IA
delete from public.ai_prompts   where feature like 'mind_vector%';
delete from public.ai_usage_log where feature like 'mind_vector%';

-- Clé de permission semée par migration_mind_vector_role_menu.sql
update public.app_roles
   set permissions = permissions #- '{menus,mind_vector}'
 where permissions ? 'menus' and (permissions->'menus') ? 'mind_vector';

commit;
