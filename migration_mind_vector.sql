-- Mind Vector — formalisation des modèles mentaux
--
-- Deux tables :
--  · mv_nodes     = l'arborescence, du sujet le plus général au plus précis.
--                   Chaque nœud porte aussi le nom des deux pôles opposés
--                   (« pole_gauche » / « pole_droit »), qui donnent le sens du
--                   dégradé des 5 positions.
--  · mv_positions = les 5 positions possibles d'un nœud (1 = un extrême,
--                   5 = l'extrême opposé), en Markdown léger (## titre,
--                   **gras**, - puce) comme partout ailleurs dans l'appli.
--
-- Une ligne par (nœud, position) plutôt que 5 colonnes : l'écriture cellule par
-- cellule est un simple upsert, sans jamais réécrire les 4 autres cases — deux
-- onglets ouverts ne s'écrasent donc pas mutuellement.

create table if not exists public.mv_nodes (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid references public.mv_nodes(id) on delete cascade,
  label       text not null default 'Nouveau sujet',
  pole_gauche text,
  pole_droit  text,
  ordre       int  not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  updated_by  text
);

create index if not exists mv_nodes_parent_idx on public.mv_nodes (parent_id, ordre, created_at);

create table if not exists public.mv_positions (
  node_id    uuid not null references public.mv_nodes(id) on delete cascade,
  pos        int  not null check (pos between 1 and 5),
  content    text not null default '',
  updated_at timestamptz not null default now(),
  updated_by text,
  primary key (node_id, pos)
);

alter table public.mv_nodes     enable row level security;
alter table public.mv_positions enable row level security;

-- Lecture : tout utilisateur connecté (les modèles mentaux serviront ensuite
-- côté usager). Écriture : admins uniquement — même règle que
-- fournisseurs_description / parametres_nationaux.
drop policy if exists "mv_nodes read" on public.mv_nodes;
create policy "mv_nodes read" on public.mv_nodes
  for select to authenticated using (true);

drop policy if exists "mv_nodes admin write" on public.mv_nodes;
create policy "mv_nodes admin write" on public.mv_nodes
  for all to authenticated
  using      (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')));

drop policy if exists "mv_positions read" on public.mv_positions;
create policy "mv_positions read" on public.mv_positions
  for select to authenticated using (true);

drop policy if exists "mv_positions admin write" on public.mv_positions;
create policy "mv_positions admin write" on public.mv_positions
  for all to authenticated
  using      (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')));

comment on table public.mv_nodes is
  'Mind Vector — arborescence des sujets, du plus général au plus précis. pole_gauche/pole_droit nomment les deux visions extrêmes du sujet.';
comment on table public.mv_positions is
  'Mind Vector — les 5 positions d''un sujet (1 = un extrême, 5 = l''extrême opposé), en Markdown léger.';
