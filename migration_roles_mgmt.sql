begin;

-- 1. Table des rôles (rôles désormais dynamiques, gérés depuis l'admin)
create table if not exists public.app_roles (
  key         text primary key,
  label       text not null,
  sort_order  int  not null default 100,
  is_system   bool not null default false,   -- protège admin/superadmin/demo de la suppression
  permissions jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);
alter table public.app_roles enable row level security;
-- Aucune policy : accès uniquement via les RPC SECURITY DEFINER ci-dessous.

-- 2. Seed des 7 rôles existants avec permissions = comportement actuel (tout visible),
--    Greg restreindra ensuite les cases côté admin.
insert into public.app_roles (key, label, sort_order, is_system, permissions) values
  ('b2c_cate', 'Utilisateur B2C CATE', 10, false, '{"access":{"user":true,"admin":false,"superadmin":false},"offers":{"comparaison_fournisseur":true,"acc":true,"box_comwatt":true,"diy":true,"solaire_batterie":true},"menus":{"admin":false,"passer_action":true,"comprendre":true,"panier":true},"submenus":{"selecteur_site":true,"facture_horaire":true,"bilan_clair":true,"ma_conso":true,"production_stockage_box":true},"segments":{"b2c":true,"b2b":false}}'::jsonb),
  ('b2c',      'Utilisateur B2C',      20, false, '{"access":{"user":true,"admin":false,"superadmin":false},"offers":{"comparaison_fournisseur":true,"acc":true,"box_comwatt":true,"diy":true,"solaire_batterie":true},"menus":{"admin":false,"passer_action":true,"comprendre":true,"panier":true},"submenus":{"selecteur_site":true,"facture_horaire":true,"bilan_clair":true,"ma_conso":true,"production_stockage_box":true},"segments":{"b2c":true,"b2b":false}}'::jsonb),
  ('b2b_cate', 'Utilisateur B2B CATE', 30, false, '{"access":{"user":true,"admin":false,"superadmin":false},"offers":{"comparaison_fournisseur":true,"acc":true,"box_comwatt":true,"diy":true,"solaire_batterie":true},"menus":{"admin":false,"passer_action":true,"comprendre":true,"panier":true},"submenus":{"selecteur_site":true,"facture_horaire":true,"bilan_clair":true,"ma_conso":true,"production_stockage_box":true},"segments":{"b2c":false,"b2b":true}}'::jsonb),
  ('b2b',      'Utilisateur B2B',      40, false, '{"access":{"user":true,"admin":false,"superadmin":false},"offers":{"comparaison_fournisseur":true,"acc":true,"box_comwatt":true,"diy":true,"solaire_batterie":true},"menus":{"admin":false,"passer_action":true,"comprendre":true,"panier":true},"submenus":{"selecteur_site":true,"facture_horaire":true,"bilan_clair":true,"ma_conso":true,"production_stockage_box":true},"segments":{"b2c":false,"b2b":true}}'::jsonb),
  ('admin',      'Admin',       50, true, '{"access":{"user":true,"admin":true,"superadmin":false},"offers":{"comparaison_fournisseur":true,"acc":true,"box_comwatt":true,"diy":true,"solaire_batterie":true},"menus":{"admin":true,"passer_action":true,"comprendre":true,"panier":true},"submenus":{"selecteur_site":true,"facture_horaire":true,"bilan_clair":true,"ma_conso":true,"production_stockage_box":true},"segments":{"b2c":true,"b2b":true}}'::jsonb),
  ('superadmin', 'Super admin', 60, true, '{"access":{"user":true,"admin":true,"superadmin":true},"offers":{"comparaison_fournisseur":true,"acc":true,"box_comwatt":true,"diy":true,"solaire_batterie":true},"menus":{"admin":true,"passer_action":true,"comprendre":true,"panier":true},"submenus":{"selecteur_site":true,"facture_horaire":true,"bilan_clair":true,"ma_conso":true,"production_stockage_box":true},"segments":{"b2c":true,"b2b":true}}'::jsonb),
  ('demo',       'Démo',        70, true, '{"access":{"user":true,"admin":false,"superadmin":false},"offers":{"comparaison_fournisseur":true,"acc":true,"box_comwatt":true,"diy":true,"solaire_batterie":true},"menus":{"admin":false,"passer_action":true,"comprendre":true,"panier":true},"submenus":{"selecteur_site":true,"facture_horaire":true,"bilan_clair":true,"ma_conso":true,"production_stockage_box":true},"segments":{"b2c":true,"b2b":true}}'::jsonb)
on conflict (key) do nothing;

-- 3. profiles.role : remplacer le CHECK statique par une FK vers app_roles (rôles dynamiques)
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_fk
  foreign key (role) references public.app_roles(key)
  on update cascade on delete restrict;

-- 4. RPC lecture (admin UI + futur enforcement)
create or replace function public.get_roles()
returns setof public.app_roles
language sql stable security definer set search_path to 'public' as $fn$
  select * from public.app_roles order by sort_order, label;
$fn$;
grant execute on function public.get_roles() to authenticated;

-- 5. RPC sauvegarde des permissions d'un rôle
create or replace function public.admin_save_role_permissions(p_key text, p_permissions jsonb)
returns void language plpgsql security definer set search_path to 'public' as $fn$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  update public.app_roles set permissions = p_permissions where key = p_key;
  if not found then raise exception 'role_not_found'; end if;
end;
$fn$;
grant execute on function public.admin_save_role_permissions(text, jsonb) to authenticated;

-- 6. RPC ajout d'un rôle (permissions par défaut minimales : accès utilisateur seul)
create or replace function public.admin_add_role(p_key text, p_label text)
returns void language plpgsql security definer set search_path to 'public' as $fn$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if p_key is null or p_key !~ '^[a-z0-9_]+$' then raise exception 'invalid_key'; end if;
  insert into public.app_roles (key, label, sort_order, is_system, permissions)
  values (p_key, coalesce(nullif(trim(p_label),''), p_key), 100, false,
    '{"access":{"user":true,"admin":false,"superadmin":false},"offers":{"comparaison_fournisseur":false,"acc":false,"box_comwatt":false,"diy":false,"solaire_batterie":false},"menus":{"admin":false,"passer_action":false,"comprendre":false,"panier":false},"submenus":{"selecteur_site":false,"facture_horaire":false,"bilan_clair":false,"ma_conso":false,"production_stockage_box":false},"segments":{"b2c":false,"b2b":false}}'::jsonb);
end;
$fn$;
grant execute on function public.admin_add_role(text, text) to authenticated;

-- 7. RPC suppression d'un rôle + réassignation des comptes concernés
create or replace function public.admin_delete_role(p_key text, p_reassign_to text)
returns void language plpgsql security definer set search_path to 'public' as $fn$
declare sys bool;
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  select is_system into sys from public.app_roles where key = p_key;
  if sys is null then raise exception 'role_not_found'; end if;
  if sys then raise exception 'role_protected'; end if;
  if p_reassign_to is null or p_reassign_to = p_key
     or not exists (select 1 from public.app_roles where key = p_reassign_to) then
     raise exception 'invalid_reassign';
  end if;
  update public.profiles set role = p_reassign_to where role = p_key;
  delete from public.app_roles where key = p_key;
end;
$fn$;
grant execute on function public.admin_delete_role(text, text) to authenticated;

-- 8. admin_set_role : valider contre app_roles (rôles dynamiques) au lieu d'une liste figée
create or replace function public.admin_set_role(target_user_id uuid, new_role text)
returns void language plpgsql security definer set search_path to 'public' as $fn$
declare target_role text;
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if not exists (select 1 from public.app_roles where key = new_role) then raise exception 'invalid_role'; end if;
  select role into target_role from public.profiles where id = target_user_id;
  if (target_role = 'superadmin' or new_role = 'superadmin') and not public.is_superadmin() then
    raise exception 'forbidden_superadmin';
  end if;
  update public.profiles set role = new_role where id = target_user_id;
end;
$fn$;

commit;
