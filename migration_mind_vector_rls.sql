-- Mind Vector — refermer l'annuaire des personnes évaluées.
--
-- `mv_personnes` porte prénom, nom et e-mail de chaque personne évaluée, comptes
-- Starvolt compris. Sa policy de lecture était `using (true)` : tout compte
-- connecté pouvait donc lister l'annuaire complet d'un simple appel PostgREST,
-- alors que l'interface ne lui en montre rien. L'écran ne protégeait que
-- l'affichage — la base, elle, répondait à qui demandait.
--
-- Nouvelle règle, calquée sur celle de `mv_reponses` :
--   · un admin / superadmin voit tout l'annuaire (il choisit qui il évalue) ;
--   · tout autre compte ne voit QUE sa propre fiche (`user_id = auth.uid()`).
--
-- Les trois points de lecture côté client restent servis :
--   · `reprendrePersonne` — la fiche mémorisée. Une fiche qui n'est pas la sienne
--     ne remonte plus (null au lieu d'une ligne rejetée ensuite en JS) : dans les
--     deux cas on rouvre le popup « pour qui ? ». Comportement inchangé.
--   · liste `fiches` — déjà réservée à `peutChoisirQui` (admin/superadmin).
--   · `ficheDuCompte` — appelée sur soi-même (« Moi-même ») ou par un admin sur
--     un autre compte. Le `insert(...).select()` qui suit a besoin d'une policy
--     SELECT sur la ligne créée : « sa propre fiche » et « admin » la couvrent.
-- La fonction edge `mind-vector` passe par le service_role et ne lit de toute
-- façon pas cette table.
--
-- Attention aussi aux policies qui INTERROGENT `mv_personnes` : celles de
-- `mv_reponses` en font un `exists`, et une sous-requête de policy subit la RLS
-- de la table qu'elle lit. Les deux cas restent couverts — le superadmin lit
-- toute fiche, et le simple utilisateur lit la sienne, qui est justement celle
-- que la sous-requête teste (`mp.user_id = auth.uid()`).

drop policy if exists "mv_personnes read"    on public.mv_personnes;
drop policy if exists "mv_personnes lecture" on public.mv_personnes;
create policy "mv_personnes lecture" on public.mv_personnes
  for select to authenticated using (
    user_id = auth.uid()
    or exists (select 1 from public.profiles p
                where p.id = auth.uid() and p.role in ('admin','superadmin'))
  );

-- `mv_reponses` : la lecture ouverte a déjà été refermée par
-- `migration_mind_vector_auteur.sql` (policy « mv_reponses lecture » : chacun ne
-- voit que ses propres classements, un superadmin voit en plus l'auto-diagnostic
-- de la personne évaluée). On se contente ici de reprendre le filet, au cas où
-- l'ancienne policy serait revenue par une réexécution de
-- `migration_mind_vector_reponses.sql`.
drop policy if exists "mv_reponses read"       on public.mv_reponses;
drop policy if exists "mv_reponses admin write" on public.mv_reponses;

comment on table public.mv_personnes is
  'Mind Vector — qui répond : un compte Starvolt (user_id) ou une personne extérieure saisie à la main. Lecture réservée aux admins et à sa propre fiche.';
