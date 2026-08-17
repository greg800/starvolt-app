-- Mind Vector — séparer l'auto-diagnostic du diagnostic par un tiers.
--
-- Une réponse n'appartient plus seulement à la personne évaluée : elle appartient
-- aussi à CELUI QUI L'A POSÉE. La clé primaire passe donc à trois colonnes, ce
-- qui permet à plusieurs personnes de classer indépendamment le même individu
-- sur le même sujet, sans se voir ni s'écraser.
--
-- Règle de visibilité : chacun ne voit que ses propres classements. Seule
-- exception, un super admin voit AUSSI l'auto-diagnostic de la personne évaluée
-- (la réponse dont l'auteur est la personne elle-même) — c'est ce qui permet de
-- comparer ce que quelqu'un dit de lui à ce qu'un tiers en pense, sans que
-- l'intéressé sache qu'on l'a déjà classé.

alter table public.mv_reponses add column if not exists auteur_id uuid references auth.users(id) on delete cascade;

-- Reprise : les réponses déjà saisies portent l'e-mail de leur auteur.
update public.mv_reponses r
   set auteur_id = u.id
  from auth.users u
 where r.auteur_id is null and lower(u.email) = lower(r.updated_by);

-- Filet : s'il en reste sans auteur identifiable, on ne les perd pas.
update public.mv_reponses
   set auteur_id = (select id from auth.users where lower(email) = 'greg@starvolt.fr')
 where auteur_id is null;

delete from public.mv_reponses where auteur_id is null;   -- au cas où le filet lui-même échoue
alter table public.mv_reponses alter column auteur_id set not null;

alter table public.mv_reponses drop constraint if exists mv_reponses_pkey;
alter table public.mv_reponses add primary key (personne_id, node_id, auteur_id);

-- ── Visibilité ─────────────────────────────────────────────────────────────
drop policy if exists "mv_reponses read" on public.mv_reponses;
drop policy if exists "mv_reponses lecture" on public.mv_reponses;
create policy "mv_reponses lecture" on public.mv_reponses
  for select to authenticated using (
    auteur_id = auth.uid()
    or (
      exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'superadmin')
      and exists (select 1 from public.mv_personnes mp
                   where mp.id = personne_id and mp.user_id = auteur_id)
    )
  );

-- ── Écriture ───────────────────────────────────────────────────────────────
-- On n'écrit JAMAIS sous le nom d'un autre : auteur_id doit être soi-même.
-- Un admin peut classer n'importe qui ; les autres ne peuvent se classer qu'eux
-- mêmes — sans quoi n'importe quel compte pourrait cataloguer n'importe qui.
drop policy if exists "mv_reponses admin write" on public.mv_reponses;
drop policy if exists "mv_reponses ecriture" on public.mv_reponses;
create policy "mv_reponses ecriture" on public.mv_reponses
  for all to authenticated
  using (
    auteur_id = auth.uid()
    and (
      exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin'))
      or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = auth.uid())
    )
  )
  with check (
    auteur_id = auth.uid()
    and (
      exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin'))
      or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = auth.uid())
    )
  );

-- Se créer sa propre fiche, pour pouvoir s'auto-diagnostiquer.
drop policy if exists "mv_personnes fiche perso" on public.mv_personnes;
create policy "mv_personnes fiche perso" on public.mv_personnes
  for insert to authenticated with check (user_id = auth.uid());

comment on column public.mv_reponses.auteur_id is
  'Qui a posé ce classement. Auteur = personne évaluée → auto-diagnostic ; sinon diagnostic par un tiers.';
