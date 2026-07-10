-- Correctif sécurité : la policy admin_write de filtres_config était ouverte à
-- « public » (ALL, USING true) → n'importe qui avec la clé anon pouvait écrire.
-- Seul AdminFiltresScreen (admin) écrit légitimement (toggle actif) → on restreint
-- les écritures aux admins/superadmins. La lecture (public_read) reste inchangée.
drop policy if exists "admin_write" on public.filtres_config;
create policy "admin_write" on public.filtres_config
  for all to authenticated
  using      (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')));
