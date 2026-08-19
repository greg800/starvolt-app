-- Mind Vector — attribuer les positions à des personnes.
--
-- Deux tables :
--  · mv_personnes — qui répond. Soit un compte Starvolt (user_id rempli), soit
--    quelqu'un d'extérieur saisi à la main. Une seule fiche par compte.
--  · mv_reponses  — la position retenue par une personne sur un sujet. Une ligne
--    par couple : la clé primaire impose à elle seule le « un seul choix ».
--    Pas de choix = pas de ligne (on supprime plutôt que de stocker un vide).

create table if not exists public.mv_personnes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  prenom      text not null,
  nom         text not null,
  email       text not null,
  commentaire text,
  created_at  timestamptz not null default now(),
  created_by  text
);

-- Un compte Starvolt ne peut avoir qu'une fiche : sans ça, deux clics sur le
-- même nom créeraient deux jeux de réponses concurrents.
create unique index if not exists mv_personnes_user_idx
  on public.mv_personnes (user_id) where user_id is not null;
create index if not exists mv_personnes_nom_idx on public.mv_personnes (nom, prenom);

create table if not exists public.mv_reponses (
  personne_id uuid not null references public.mv_personnes(id) on delete cascade,
  node_id     uuid not null references public.mv_nodes(id)     on delete cascade,
  pos         int  not null check (pos between 1 and 5),
  updated_at  timestamptz not null default now(),
  updated_by  text,
  primary key (personne_id, node_id)
);
create index if not exists mv_reponses_node_idx on public.mv_reponses (node_id, pos);

alter table public.mv_personnes enable row level security;
alter table public.mv_reponses  enable row level security;

-- ⚠️ Les lectures étaient ouvertes à tout compte connecté (`using (true)`).
-- Elles ont été refermées depuis, et les policies définitives vivent ailleurs :
--   · `mv_personnes` → `migration_mind_vector_rls.sql`    (admin + sa propre fiche)
--   · `mv_reponses`  → `migration_mind_vector_auteur.sql` (ses propres classements)
-- Ce fichier ne les recrée donc plus : réexécuté un jour, il rouvrirait
-- l'annuaire des personnes évaluées à n'importe quel utilisateur.

drop policy if exists "mv_personnes admin write" on public.mv_personnes;
create policy "mv_personnes admin write" on public.mv_personnes
  for all to authenticated
  using      (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')));

comment on table public.mv_personnes is
  'Mind Vector — qui répond : un compte Starvolt (user_id) ou une personne extérieure saisie à la main.';
comment on table public.mv_reponses is
  'Mind Vector — position (1 à 5) retenue par une personne sur un sujet. Pas de ligne = aucun choix.';
