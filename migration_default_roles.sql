begin;

-- 1. Colonnes : rôle par défaut au signup pour chaque segment
alter table public.app_roles
  add column if not exists is_default_b2c boolean not null default false,
  add column if not exists is_default_b2b boolean not null default false;

-- 2. Au plus UN rôle par défaut par segment (index uniques partiels)
create unique index if not exists app_roles_one_default_b2c
  on public.app_roles (is_default_b2c) where is_default_b2c;
create unique index if not exists app_roles_one_default_b2b
  on public.app_roles (is_default_b2b) where is_default_b2b;

-- 3. Seed : conserve le comportement actuel (b2c_cate / b2b_cate)
update public.app_roles set is_default_b2c = true where key = 'b2c_cate';
update public.app_roles set is_default_b2b = true where key = 'b2b_cate';

-- 4. Renommer un rôle (label uniquement)
create or replace function public.admin_rename_role(p_key text, p_label text)
returns void language plpgsql security definer set search_path to 'public' as $fn$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if p_label is null or trim(p_label) = '' then raise exception 'invalid_label'; end if;
  update public.app_roles set label = trim(p_label) where key = p_key;
  if not found then raise exception 'role_not_found'; end if;
end;
$fn$;
grant execute on function public.admin_rename_role(text, text) to authenticated;

-- 5. Définir le rôle par défaut d'un segment (déplace le drapeau de façon atomique)
create or replace function public.admin_set_default_role(p_key text, p_segment text)
returns void language plpgsql security definer set search_path to 'public' as $fn$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
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
grant execute on function public.admin_set_default_role(text, text) to authenticated;

-- 6. Lire le rôle par défaut d'un segment au signup (accountType : 'particulier' | 'entreprise')
create or replace function public.get_default_role(p_account_type text)
returns text language sql stable security definer set search_path to 'public' as $fn$
  select key from public.app_roles
  where case when p_account_type = 'entreprise' then is_default_b2b else is_default_b2c end
  limit 1;
$fn$;
grant execute on function public.get_default_role(text) to anon, authenticated;

commit;
