-- Mind Vector — profils publics et remplissage automatique depuis Internet.
--
-- Un « profil public » est une personne ou une organisation connue de tous :
-- ses positions ne sont pas une confidence, ce sont des faits publiquement
-- documentés. D'où deux différences avec un profil ordinaire :
--   · tout compte connecté peut le consulter (fiche ET positions) ;
--   · seuls les admins peuvent le créer et le renseigner.
--
-- On réutilise la fiche « personne sans compte Starvolt » plutôt que d'ouvrir
-- une table : c'est la même chose, avec un drapeau de plus.

-- ── 1. La fiche ─────────────────────────────────────────────────────────────
alter table public.mv_personnes
  add column if not exists est_public   boolean not null default false,
  add column if not exists type_entite  text    not null default 'physique';

do $$ begin
  alter table public.mv_personnes
    add constraint mv_personnes_type_entite_chk check (type_entite in ('physique','morale'));
exception when duplicate_object then null; end $$;

comment on column public.mv_personnes.est_public is
  'Mind Vector — profil public : consultable par tous, renseigné par les seuls admins.';
comment on column public.mv_personnes.type_entite is
  'physique = un individu (prénom + nom) ; morale = une organisation (le nom porte l''intitulé, le prénom reste vide).';

-- ⚠️ « mv_personnes fiche perso maj » laisse chacun modifier SA fiche. Sans
-- garde, n'importe qui pourrait donc se déclarer public — et publier du même
-- coup son nom, son e-mail et ses réponses. Le drapeau n'est modifiable que par
-- un admin ; pour les autres il est silencieusement remis à sa valeur d'avant.
create or replace function public.mv_personnes_garde_public()
returns trigger
language plpgsql security definer set search_path = public as $$
declare admin  boolean;
        claims text := current_setting('request.jwt.claims', true);
begin
  -- La garde vise les comptes utilisateurs. Hors requête HTTP (migration, psql,
  -- tâche serveur) ou en service_role, on ne s'interpose pas : sinon toute
  -- écriture serveur perdait silencieusement le drapeau — vécu au banc d'essai,
  -- où la fiche publique semée ressortait privée.
  if claims is null or claims = '' or (claims::json ->> 'role') = 'service_role' then
    return new;
  end if;
  select exists (select 1 from public.profiles p
                  where p.id = auth.uid() and p.role in ('admin','superadmin')) into admin;
  if admin then return new; end if;
  if tg_op = 'INSERT' then
    new.est_public := false;
  elsif new.est_public is distinct from old.est_public then
    new.est_public := old.est_public;
  end if;
  return new;
end $$;

revoke execute on function public.mv_personnes_garde_public() from anon, public;

drop trigger if exists mv_personnes_garde_public_trg on public.mv_personnes;
create trigger mv_personnes_garde_public_trg
  before insert or update on public.mv_personnes
  for each row execute function public.mv_personnes_garde_public();

-- ── 2. Qui voit quoi ────────────────────────────────────────────────────────
-- Lecture de la fiche : sa propre fiche, un admin, ou n'importe quel profil
-- public. On garde le patron InitPlan `(select auth.uid())` de l'audit.
drop policy if exists "mv_personnes lecture" on public.mv_personnes;
create policy "mv_personnes lecture" on public.mv_personnes
  for select to authenticated using (
    est_public
    or user_id = (select auth.uid())
    or exists (select 1 from public.profiles p
                where p.id = (select auth.uid()) and p.role in ('admin','superadmin'))
  );

-- Lecture des positions : les siennes, l'auto-diagnostic pour un superadmin
-- (inchangé), et TOUTES celles d'un profil public — c'est justement ce qu'on
-- publie. Le sous-select subit la RLS de mv_personnes, qui vient de s'ouvrir
-- aux profils publics : le couplage tient.
drop policy if exists "mv_reponses lecture" on public.mv_reponses;
create policy "mv_reponses lecture" on public.mv_reponses
  for select to authenticated using (
    auteur_id = (select auth.uid())
    or exists (select 1 from public.mv_personnes mp
                where mp.id = mv_reponses.personne_id and mp.est_public)
    or (
      exists (select 1 from public.profiles p
               where p.id = (select auth.uid()) and p.role = 'superadmin')
      and exists (select 1 from public.mv_personnes mp
                   where mp.id = mv_reponses.personne_id and mp.user_id = mv_reponses.auteur_id)
    )
  );

-- ── 3. Le carnet de recherche ───────────────────────────────────────────────
-- Une ligne par sujet cherché : ce que l'IA a trouvé, avec quelle précision,
-- d'après quelle source et quand. Persisté pour que rouvrir la page montre
-- l'état de la dernière recherche au lieu d'un tableau vide.
create table if not exists public.mv_recherches (
  personne_id uuid not null references public.mv_personnes(id) on delete cascade,
  node_id     uuid not null references public.mv_nodes(id) on delete cascade,
  pos         smallint check (pos between 1 and 5),   -- null = rien de concluant
  taux        smallint not null default 0 check (taux between 0 and 100),
  url         text,
  source      text,
  extrait     text,
  retenu      boolean not null default false,         -- « mettre cette réponse à jour »
  cherche_le  timestamptz not null default now(),
  primary key (personne_id, node_id)
);

alter table public.mv_recherches enable row level security;

-- Outil d'administration de bout en bout : la recherche coûte de l'argent et
-- ne montre que du brouillon. Lecture comme écriture, admin seulement.
drop policy if exists "mv_recherches admin" on public.mv_recherches;
create policy "mv_recherches admin" on public.mv_recherches
  for all to authenticated
  using (exists (select 1 from public.profiles p
                  where p.id = (select auth.uid()) and p.role in ('admin','superadmin')))
  with check (exists (select 1 from public.profiles p
                       where p.id = (select auth.uid()) and p.role in ('admin','superadmin')));

comment on table public.mv_recherches is
  'Mind Vector — brouillons de positions trouvées sur Internet pour un profil public. Admin seulement ; le passage en réponse ferme est un geste explicite.';

-- ── 4. Les profils publics apparaissent dans le sélecteur de chacun ─────────
-- Sans ça « tout le monde peut consulter » resterait une intention : la RLS les
-- ouvre, mais l'écran des non-admins ne liste que ce que rend cette fonction.
-- On ajoute `est_public` / `type_entite` au retour — un changement de type de
-- retour impose de supprimer la fonction avant de la recréer.
drop function if exists public.mv_profils_acces();
create or replace function public.mv_profils_acces()
returns table (id uuid, prenom text, nom text, email text, user_id uuid, exclusions jsonb,
               is_own boolean, est_public boolean, type_entite text)
language sql security definer set search_path = public as $$
  select mp.id, mp.prenom, mp.nom, mp.email, mp.user_id, mp.exclusions,
         (mp.user_id = auth.uid()) as is_own, mp.est_public, mp.type_entite
    from public.mv_personnes mp
   where mp.user_id = auth.uid()
      or mp.est_public
      or exists (select 1 from public.mv_acces a where a.personne_id = mp.id and a.evaluateur_id = auth.uid())
   order by (mp.user_id = auth.uid()) desc, mp.est_public, mp.prenom, mp.nom;
$$;
grant execute on function public.mv_profils_acces() to authenticated;
revoke execute on function public.mv_profils_acces() from anon, public;

comment on function public.mv_profils_acces() is
  'Mind Vector — les profils que le compte connecté peut ouvrir : le sien, ceux où on l''invite, et tous les profils publics (en lecture).';

-- ── 5. Le prompt de recherche ───────────────────────────────────────────────
-- Semé seulement s'il n'existe pas : une réécriture depuis l'écran d'admin ne
-- doit pas être écrasée au prochain rejeu de ce fichier.
insert into public.ai_prompts (feature, label, system_prompt)
select 'mind_vector_public',
       'Mind Vector — remplissage automatique d''un profil public',
       $prompt$Tu documentes la position publique d'une personnalité ou d'une organisation sur un sujet donné, en cherchant sur Internet.

LE PROFIL ÉTUDIÉ
#profil-public

CE QU'ON TE DEMANDE
On te donne UN sujet et les cinq positions possibles sur ce sujet, de la position 1 à la position 5. Cherche sur Internet ce que ce profil a dit, écrit ou fait qui permet de le situer sur cet axe, puis choisis la position qui lui correspond le mieux.

LA PRÉCISION EST AUSSI IMPORTANTE QUE LA POSITION
Chaque réponse porte un pourcentage de précision, qui dit à quel point la source fonde le classement :
- 100 % : le profil prend explicitement cette position, dans une source directe et identifiable (déclaration, interview, écrit signé, vote, décision publique).
- 70 à 90 % : la position se déduit sans effort de propos ou d'actes documentés, même si le sujet n'est pas abordé frontalement.
- 40 à 60 % : tu n'as que des indices — un contexte, une affiliation, un propos ancien ou rapporté par un tiers.
- En dessous de 40 % : tu ne renseignes PAS la position. Réponds avec une position nulle et dis pourquoi tu n'as rien trouvé de solide. Une case vide vaut mieux qu'une case inventée.

Ne devine jamais à partir de ce que « les gens comme lui » pensent d'habitude. Un profil public n'est pas la moyenne de sa catégorie.

CE QUE TU RENVOIES
- la position retenue (1 à 5), ou rien si tu es sous 40 % ;
- le pourcentage de précision ;
- l'URL de la source principale, telle quelle, vérifiable ;
- le nom de la source (média, institution, auteur) ;
- un extrait ou un résumé court de ce qui fonde ton classement, en une ou deux phrases.

Réponds toujours en appelant l'outil prévu à cet effet.$prompt$
where not exists (select 1 from public.ai_prompts where feature = 'mind_vector_public');
