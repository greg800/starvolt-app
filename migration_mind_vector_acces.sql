-- Mind Vector — qui a le droit d'évaluer quel profil.
--
-- Jusqu'ici seuls un admin/superadmin pouvaient classer quelqu'un d'autre, et
-- chacun ne se classait que lui-même. On ouvre une troisième voie : le
-- propriétaire d'un profil INVITE nommément d'autres comptes à l'évaluer. Un
-- superadmin, lui, garde accès à tout le monde.
--
-- Une ligne = « ce compte peut évaluer ce profil ». Le nom de l'invité est
-- recopié à l'invitation (evaluateur_*), pour afficher la liste sans relire la
-- table des comptes.

create table if not exists public.mv_acces (
  personne_id       uuid not null references public.mv_personnes(id) on delete cascade,
  evaluateur_id     uuid not null references auth.users(id) on delete cascade,
  evaluateur_email  text,
  evaluateur_prenom text,
  evaluateur_nom    text,
  granted_by        text,
  created_at        timestamptz not null default now(),
  primary key (personne_id, evaluateur_id)
);

alter table public.mv_acces enable row level security;

-- Lecture : le propriétaire du profil (pour gérer ses invités), l'invité
-- lui-même (pour retrouver le profil dans sa liste), ou un superadmin.
drop policy if exists "mv_acces lecture" on public.mv_acces;
create policy "mv_acces lecture" on public.mv_acces
  for select to authenticated using (
    evaluateur_id = auth.uid()
    or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = auth.uid())
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'superadmin')
  );

-- Écriture : inviter ou révoquer, réservé au propriétaire du profil ou à un
-- superadmin.
drop policy if exists "mv_acces ecriture" on public.mv_acces;
create policy "mv_acces ecriture" on public.mv_acces
  for all to authenticated
  using (
    exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = auth.uid())
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'superadmin')
  )
  with check (
    exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = auth.uid())
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'superadmin')
  );

-- ── Écriture des réponses : ajouter le cas de l'invité ─────────────────────────
-- Un invité écrit ses propres classements (auteur_id = lui) sur un profil pour
-- lequel il a reçu un accès. On reprend la policy existante en lui ajoutant ce
-- troisième cas, à côté de « admin » et « c'est ma fiche ».
drop policy if exists "mv_reponses ecriture" on public.mv_reponses;
create policy "mv_reponses ecriture" on public.mv_reponses
  for all to authenticated
  using (
    auteur_id = auth.uid()
    and (
      exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin'))
      or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = auth.uid())
      or exists (select 1 from public.mv_acces a where a.personne_id = mv_reponses.personne_id and a.evaluateur_id = auth.uid())
    )
  )
  with check (
    auteur_id = auth.uid()
    and (
      exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin'))
      or exists (select 1 from public.mv_personnes mp where mp.id = personne_id and mp.user_id = auth.uid())
      or exists (select 1 from public.mv_acces a where a.personne_id = mv_reponses.personne_id and a.evaluateur_id = auth.uid())
    )
  );

-- ── RPCs ───────────────────────────────────────────────────────────────────────
-- Trouver un compte par son e-mail exact, sans exposer toute la table des
-- comptes à un simple utilisateur qui invite quelqu'un.
create or replace function public.mv_lookup_email(p_email text)
returns table (id uuid, prenom text, nom text)
language sql security definer set search_path = public as $$
  select u.id, pr.prenom, pr.nom
    from auth.users u
    left join public.profiles pr on pr.id = u.id
   where lower(u.email) = lower(trim(p_email))
   limit 1;
$$;
grant execute on function public.mv_lookup_email(text) to authenticated;

-- Les profils que le compte connecté a le droit d'évaluer : le sien d'abord,
-- puis ceux auxquels il a été invité. Passe par une fonction pour rester
-- indépendant de la policy de lecture de mv_personnes (qui peut se resserrer).
create or replace function public.mv_profils_acces()
returns table (id uuid, prenom text, nom text, email text, user_id uuid, exclusions jsonb, is_own boolean)
language sql security definer set search_path = public as $$
  select mp.id, mp.prenom, mp.nom, mp.email, mp.user_id, mp.exclusions,
         (mp.user_id = auth.uid()) as is_own
    from public.mv_personnes mp
   where mp.user_id = auth.uid()
      or exists (select 1 from public.mv_acces a where a.personne_id = mp.id and a.evaluateur_id = auth.uid())
   order by (mp.user_id = auth.uid()) desc, mp.prenom, mp.nom;
$$;
grant execute on function public.mv_profils_acces() to authenticated;

-- Les invités d'un profil, avec le nombre de sujets qu'ils ont déjà classés.
-- On rend un COMPTE, jamais le contenu : le propriétaire voit qui a répondu et
-- combien, sans lire ce que chacun a coché. Réservé au propriétaire ou à un
-- superadmin (sinon la fonction ne renvoie rien).
create or replace function public.mv_evaluateurs(p_personne_id uuid)
returns table (evaluateur_id uuid, prenom text, nom text, email text, repondu bigint)
language sql security definer set search_path = public as $$
  select a.evaluateur_id, a.evaluateur_prenom, a.evaluateur_nom, a.evaluateur_email,
         (select count(distinct r.node_id) from public.mv_reponses r
           where r.personne_id = p_personne_id and r.auteur_id = a.evaluateur_id) as repondu
    from public.mv_acces a
   where a.personne_id = p_personne_id
     and (
       exists (select 1 from public.mv_personnes mp where mp.id = p_personne_id and mp.user_id = auth.uid())
       or exists (select 1 from public.profiles pr where pr.id = auth.uid() and pr.role = 'superadmin')
     )
   order by a.evaluateur_prenom, a.evaluateur_nom;
$$;
grant execute on function public.mv_evaluateurs(uuid) to authenticated;

comment on table public.mv_acces is
  'Mind Vector — droit d''évaluer un profil : le propriétaire invite nommément d''autres comptes ; un superadmin voit tout le monde.';
