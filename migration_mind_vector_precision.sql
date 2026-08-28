-- Mind Vector — précision d'une évaluation, et pondération de l'analyse.
--
-- Plusieurs personnes peuvent classer le même profil : la personne elle-même,
-- des proches, des collègues. Toutes ne se valent pas. On demande donc à chaque
-- évaluateur, AVANT qu'il ne commence, quelle précision il accorde à son propre
-- regard, en pourcentage. L'auto-évaluation vaut 80 % — même soi-même on ne se
-- voit pas entièrement ; un tiers descend à 60 % ou moins.
--
-- Une ligne = « ce compte estime son évaluation de ce profil à N % ». C'est un
-- réglage de l'évaluateur sur le profil, pas une propriété de chaque réponse :
-- une seule ligne par couple, quel que soit le nombre de sujets classés.
--
-- La colonne s'appelle `taux` et non `precision` : PRECISION est un mot-clé SQL
-- (double precision), lisible seulement entre guillemets dans les policies.

create table if not exists public.mv_precisions (
  personne_id uuid not null references public.mv_personnes(id) on delete cascade,
  auteur_id   uuid not null references auth.users(id) on delete cascade,
  taux        smallint not null default 60 check (taux between 5 and 100),
  updated_at  timestamptz not null default now(),
  primary key (personne_id, auteur_id)
);

alter table public.mv_precisions enable row level security;

-- Lecture : l'évaluateur voit la sienne, le propriétaire du profil voit celles
-- de ses évaluateurs (il en a besoin pour pondérer son analyse), un admin voit
-- tout. Le sous-select sur mv_personnes subit la RLS de cette table : elle
-- laisse toujours lire « sa propre fiche », c'est exactement ce qu'on teste.
drop policy if exists "mv_precisions lecture" on public.mv_precisions;
create policy "mv_precisions lecture" on public.mv_precisions
  for select to authenticated using (
    auteur_id = (select auth.uid())
    or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = (select auth.uid()))
    or exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('admin','superadmin'))
  );

-- Écriture : chacun ne règle QUE sa propre précision, et seulement sur un
-- profil qu'il a le droit d'évaluer. Même triplet de cas que « mv_reponses
-- ecriture » : admin, sa propre fiche, ou invité nommément.
drop policy if exists "mv_precisions ecriture" on public.mv_precisions;
create policy "mv_precisions ecriture" on public.mv_precisions
  for all to authenticated
  using (
    auteur_id = (select auth.uid())
    and (
      exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('admin','superadmin'))
      or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = (select auth.uid()))
      or exists (select 1 from public.mv_acces a where a.personne_id = mv_precisions.personne_id and a.evaluateur_id = (select auth.uid()))
    )
  )
  with check (
    auteur_id = (select auth.uid())
    and (
      exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('admin','superadmin'))
      or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = (select auth.uid()))
      or exists (select 1 from public.mv_acces a where a.personne_id = mv_precisions.personne_id and a.evaluateur_id = (select auth.uid()))
    )
  );

-- ── Reprise de l'existant ──────────────────────────────────────────────────
-- Ce qui est déjà en base n'a jamais été interrogé : on applique la règle par
-- défaut posée par Greg — 80 % quand l'auteur est la personne elle-même, 60 %
-- sinon. Rejouable : `on conflict do nothing` ne réécrit pas un choix explicite.
insert into public.mv_precisions (personne_id, auteur_id, taux)
select distinct r.personne_id, r.auteur_id,
       case when mp.user_id is not null and mp.user_id = r.auteur_id then 80 else 60 end
  from public.mv_reponses r
  join public.mv_personnes mp on mp.id = r.personne_id
on conflict (personne_id, auteur_id) do nothing;

-- ── Qui a classé ce profil, et avec quelle précision ───────────────────────
-- Sert au choix de la portée de l'analyse : « seulement l'auto-évaluation »,
-- « tout le monde » ou « ces évaluateurs-là ». Rend un COMPTE de sujets classés,
-- jamais le contenu des réponses. Même garde que mv_synthese : réservé au
-- propriétaire du profil et au superadmin (sinon la fonction ne rend rien).
create or replace function public.mv_auteurs(p_personne_id uuid)
returns table (auteur_id uuid, nom text, is_self boolean, repondu bigint, taux smallint)
language sql security definer set search_path = public as $$
  select r.auteur_id,
         coalesce(nullif(trim(concat(pr.prenom, ' ', pr.nom)), ''), au.email, 'Anonyme') as nom,
         (mp.user_id is not null and mp.user_id = r.auteur_id) as is_self,
         count(distinct r.node_id) as repondu,
         coalesce(mq.taux,
                  case when mp.user_id is not null and mp.user_id = r.auteur_id then 80 else 60 end)::smallint as taux
    from public.mv_reponses r
    join public.mv_personnes mp on mp.id = r.personne_id
    left join public.profiles pr on pr.id = r.auteur_id
    left join auth.users au on au.id = r.auteur_id
    left join public.mv_precisions mq
           on mq.personne_id = r.personne_id and mq.auteur_id = r.auteur_id
   where r.personne_id = p_personne_id
     and (
       exists (select 1 from public.mv_personnes m2 where m2.id = p_personne_id and m2.user_id = auth.uid())
       or exists (select 1 from public.profiles p3 where p3.id = auth.uid() and p3.role = 'superadmin')
     )
   group by r.auteur_id, pr.prenom, pr.nom, au.email, mp.user_id, mq.taux
   order by (mp.user_id is not null and mp.user_id = r.auteur_id) desc, 2;
$$;

grant execute on function public.mv_auteurs(uuid) to authenticated;
revoke execute on function public.mv_auteurs(uuid) from anon, public;

comment on table public.mv_precisions is
  'Mind Vector — précision (%) que chaque évaluateur accorde à son propre regard sur un profil. 80 % = auto-évaluation, 60 % ou moins pour un tiers. Pondère l''analyse.';
comment on function public.mv_auteurs(uuid) is
  'Mind Vector — qui a classé ce profil, combien de sujets et avec quelle précision. Réservé au propriétaire du profil et au superadmin.';
