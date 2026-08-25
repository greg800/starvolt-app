-- Audit sécurité — remplacer l'e-mail admin en dur dans les policies RLS
--
-- Cinq policies d'écriture testaient `auth.email() = 'greg@starvolt.fr'`, le même
-- anti-pattern que le fix C3 sur les edge functions (generate-quiz, mind-vector).
-- On passe au rôle lu en base, via is_admin() — qui couvre 'admin' et
-- 'superadmin'. Élargissement assumé : tout admin peut désormais écrire sur ces
-- tables, plus seulement le compte greg@starvolt.fr.
--
-- Deux précautions :
--
-- 1. Trois de ces policies (`admin_all` sur prix_spot, spot_metadata et
--    tarifs_electricite) sont ouvertes au rôle `public`. Or is_admin() n'est plus
--    exécutable par `anon` depuis migration_secu_anon_secdef_v3.sql : une lecture
--    anonyme aurait échoué sur un refus de privilège au lieu de passer par la
--    policy `public_read`. On les restreint donc à `authenticated`. La lecture
--    anonyme de ces tables reste assurée par `public_read` (qual `true`), qui est
--    inchangée.
--
-- 2. `(select is_admin())` et non `is_admin()` : ces tables se lisent en masse
--    (prix_spot notamment), et les policies permissives d'une même commande sont
--    évaluées en OR sur chaque ligne. Encapsulé, l'appel devient un InitPlan —
--    même raison que pour auth.uid() dans migration_perf_rls_auth_uid_v2.sql.

alter policy "admin_all" on public.prix_spot
  to authenticated using ((select is_admin())) with check ((select is_admin()));

alter policy "admin_all" on public.spot_metadata
  to authenticated using ((select is_admin())) with check ((select is_admin()));

alter policy "admin_all" on public.tarifs_electricite
  to authenticated using ((select is_admin())) with check ((select is_admin()));

alter policy "prix_materiaux_admin_write" on public.prix_materiaux
  using ((select is_admin())) with check ((select is_admin()));

alter policy "profils_production_admin_write" on public.profils_production
  using ((select is_admin())) with check ((select is_admin()));

-- Contrôle : plus aucune policy ne mentionne un e-mail en dur.
select schemaname, tablename, policyname, qual
from pg_policies
where schemaname in ('public', 'storage')
  and (coalesce(qual, '') || ' ' || coalesce(with_check, '')) like '%@starvolt.fr%'
order by 1, 2, 3;
