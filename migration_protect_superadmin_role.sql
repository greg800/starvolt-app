begin;

-- Seul un super admin peut modifier le rôle « superadmin » (permissions, nom, défaut).
-- Un admin standard ne doit pouvoir toucher aucun paramètre de ce rôle.

create or replace function public.admin_save_role_permissions(p_key text, p_permissions jsonb)
returns void language plpgsql security definer set search_path to 'public' as $fn$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if p_key = 'superadmin' and not public.is_superadmin() then raise exception 'forbidden_superadmin'; end if;
  update public.app_roles set permissions = p_permissions where key = p_key;
  if not found then raise exception 'role_not_found'; end if;
end;
$fn$;

create or replace function public.admin_rename_role(p_key text, p_label text)
returns void language plpgsql security definer set search_path to 'public' as $fn$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if p_key = 'superadmin' and not public.is_superadmin() then raise exception 'forbidden_superadmin'; end if;
  if p_label is null or trim(p_label) = '' then raise exception 'invalid_label'; end if;
  update public.app_roles set label = trim(p_label) where key = p_key;
  if not found then raise exception 'role_not_found'; end if;
end;
$fn$;

create or replace function public.admin_set_default_role(p_key text, p_segment text)
returns void language plpgsql security definer set search_path to 'public' as $fn$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if p_key = 'superadmin' and not public.is_superadmin() then raise exception 'forbidden_superadmin'; end if;
  if not exists (select 1 from public.app_roles where key = p_key) then raise exception 'role_not_found'; end if;
  if p_segment = 'b2c' then
    update public.app_roles set is_default_b2c = false where is_default_b2c and key <> p_key;
    update public.app_roles set is_default_b2c = true  where key = p_key;
  elsif p_segment = 'b2b' then
    update public.app_roles set is_default_b2b = false where is_default_b2b and key <> p_key;
    update public.app_roles set is_default_b2b = true  where key = p_key;
  else
    raise exception 'invalid_segment';
  end if;
end;
$fn$;

commit;
