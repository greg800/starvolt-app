begin;

-- 1. Retirer l'ancienne contrainte AVANT de réécrire les rôles
--    (sinon l'UPDATE écrit des valeurs encore interdites par l'ancien CHECK)
alter table public.profiles drop constraint if exists profiles_role_check;

-- 2. Migrer les comptes existants 'user' / null selon le type de compte du site actif
--    (entreprise -> b2b_cate, sinon -> b2c_cate ; repli : tout site entreprise -> b2b_cate)
update public.profiles p
set role = coalesce(
  (select case when s.account_type = 'entreprise' then 'b2b_cate' else 'b2c_cate' end
     from public.sites s where s.id = p.active_site_id),
  case when exists (select 1 from public.sites s
                    where s.user_id = p.id and s.account_type = 'entreprise')
       then 'b2b_cate' else 'b2c_cate' end
)
where p.role is null or p.role = 'user';

-- 3. Nouvelle contrainte CHECK (retire 'user', ajoute les 4 rôles utilisateur)
alter table public.profiles add constraint profiles_role_check
  check (role in ('b2c_cate','b2c','b2b_cate','b2b','admin','superadmin','demo'));

-- 4. Nouveau rôle par défaut
alter table public.profiles alter column role set default 'b2c_cate';

-- 5. admin_set_role autorise les nouveaux rôles (garde-fous superadmin inchangés)
create or replace function public.admin_set_role(target_user_id uuid, new_role text)
returns void language plpgsql security definer set search_path to 'public' as $fn$
declare target_role text;
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if new_role not in ('b2c_cate','b2c','b2b_cate','b2b','admin','superadmin') then
    raise exception 'invalid_role';
  end if;
  select role into target_role from public.profiles where id = target_user_id;
  if (target_role = 'superadmin' or new_role = 'superadmin') and not public.is_superadmin() then
    raise exception 'forbidden_superadmin';
  end if;
  update public.profiles set role = new_role where id = target_user_id;
end;
$fn$;

commit;
