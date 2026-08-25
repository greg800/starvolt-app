-- Audit performance — P1 : encapsuler les appels auth.*() dans les policies RLS
--
-- Sans encapsulation, Postgres réévalue auth.uid() (ou auth.email(), auth.role()…)
-- pour chaque ligne examinée. `(select auth.uid())` est un InitPlan : évalué une
-- seule fois par requête.
--
-- La première passe (migration_perf_rls_auth_uid.sql) n'a traité que les 9
-- policies ayant un fichier de migration local. Celles créées directement dans
-- le dashboard restaient à faire, et certaines tables déjà touchées avaient des
-- policies oubliées (mv_personnes « fiche perso », mv_reponses « lecture »).
--
-- D'où une réécriture dynamique plutôt qu'une énumération : on balaie
-- pg_policies et on reconstruit chaque expression. On couvre toute la famille
-- auth.*() et pas seulement auth.uid() : cinq policies (tarifs_electricite,
-- prix_spot, spot_metadata, prix_materiaux, profils_production) utilisent
-- auth.email().
--
-- Normalisation en deux temps pour rester idempotent : on déplie d'abord les
-- occurrences déjà encapsulées, puis on encapsule tout uniformément. Un simple
-- remplacement produirait sinon `(select (select auth.uid()))` sur les policies
-- déjà corrigées.

do $$
declare
  p record;
  q text;
  c text;
  stmt text;
  n int := 0;
  -- pg_policies restitue une encapsulation existante sous la forme
  -- « ( SELECT auth.uid() AS uid) » : on la déplie avant de ré-encapsuler.
  deplier constant text := '\( SELECT (auth\.\w+\(\)) AS \w+\)';
  encapsuler constant text := '(auth\.\w+\(\))';
begin
  for p in
    select schemaname, tablename, policyname, qual, with_check
    from pg_policies
    where schemaname in ('public', 'storage')
      and (coalesce(qual, '') || ' ' || coalesce(with_check, '')) like '%auth.%(%'
  loop
    q := p.qual;
    c := p.with_check;
    if q is not null then
      q := regexp_replace(q, deplier, '\1', 'g');
      q := regexp_replace(q, encapsuler, '(select \1)', 'g');
    end if;
    if c is not null then
      c := regexp_replace(c, deplier, '\1', 'g');
      c := regexp_replace(c, encapsuler, '(select \1)', 'g');
    end if;

    stmt := format('alter policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
    if q is not null then stmt := stmt || format(' using (%s)', q); end if;
    if c is not null then stmt := stmt || format(' with check (%s)', c); end if;

    execute stmt;
    n := n + 1;
  end loop;
  raise notice 'Policies réécrites : %', n;
end $$;

-- Contrôle : doit renvoyer 0 ligne.
--
-- On retire d'abord toutes les occurrences encapsulées, telles que pg_policies
-- les restitue, puis on cherche ce qui reste. Attention au piège : pg_policies
-- rend le sous-select en majuscules (« ( SELECT auth.uid() AS uid) »), donc un
-- test `not like '%select auth.uid()%'` en minuscules ne filtre rien — c'est ce
-- qui avait fait croire à un échec de cette migration.
select schemaname, tablename, policyname
from pg_policies
where schemaname in ('public', 'storage')
  and regexp_replace(coalesce(qual, '') || ' ' || coalesce(with_check, ''),
                     '\( SELECT auth\.\w+\(\) AS \w+\)', '', 'g') like '%auth.%(%'
order by 1, 2, 3;
