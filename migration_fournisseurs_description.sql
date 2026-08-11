-- Description des fournisseurs — texte rédigé côté admin, affiché aux usagers
-- dans le comparatif (encart « … : mais qui est ce fournisseur ? »).
-- Une ligne par fournisseur, la clé étant le nom tel qu'il est saisi dans
-- tarifs_electricite.fournisseur : pas de table de fournisseurs ailleurs, et en
-- créer une obligerait à migrer toutes les grilles existantes.

create table if not exists public.fournisseurs_description (
  fournisseur text primary key,
  description text not null default '',
  updated_at  timestamptz not null default now(),
  updated_by  text
);

alter table public.fournisseurs_description enable row level security;

-- Lecture : tout utilisateur connecté (le texte s'affiche dans le comparatif).
drop policy if exists "fournisseurs_desc read" on public.fournisseurs_description;
create policy "fournisseurs_desc read" on public.fournisseurs_description
  for select to authenticated using (true);

-- Écriture : admins uniquement — même règle que parametres_nationaux.
drop policy if exists "fournisseurs_desc admin write" on public.fournisseurs_description;
create policy "fournisseurs_desc admin write" on public.fournisseurs_description
  for all to authenticated
  using      (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')));

comment on table public.fournisseurs_description is
  'Présentation d''un fournisseur, en Markdown léger (## titre, **gras**, - puce). Affichée dans le comparatif fournisseurs, encart « mais qui est ce fournisseur ? ».';
