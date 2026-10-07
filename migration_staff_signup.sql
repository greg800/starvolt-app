-- 1. Garde du rôle : un utilisateur ne peut plus réécrire profiles.role lui-même
--    (la policy « Profil personnel » + le droit UPDATE sur la colonne le
--    permettaient : n'importe quel inscrit pouvait se passer superadmin).
--    À l'inscription, il ne peut prendre qu'un rôle sans accès admin.
--    Les RPC SECURITY DEFINER (admin_set_role…) et service_role ne sont pas
--    concernées : elles ne tournent pas sous le rôle « authenticated ».
-- 2. Comptes « staff » : copie du site « Greg Site 5 » pour tester le parcours
--    client avec de vraies données, sans toucher au site d'origine.
begin;

create or replace function public.role_grants_admin(p_key text)
returns boolean language sql stable security definer set search_path to 'public' as $fn$
  select p_key in ('admin','superadmin') or exists (
    select 1 from public.app_roles r where r.key = p_key
      and (coalesce((r.permissions->'access'->>'admin')::boolean, false)
        or coalesce((r.permissions->'access'->>'superadmin')::boolean, false)));
$fn$;
revoke execute on function public.role_grants_admin(text) from anon, public;
grant execute on function public.role_grants_admin(text) to authenticated;

create or replace function public.profiles_guard_role()
returns trigger language plpgsql set search_path to 'public' as $fn$
begin
  if current_user not in ('authenticated', 'anon') then return new; end if;
  if tg_op = 'UPDATE' then
    if new.role is distinct from old.role then raise exception 'role_change_forbidden'; end if;
  elsif new.role is not null and public.role_grants_admin(new.role) then
    raise exception 'role_forbidden';
  end if;
  return new;
end;
$fn$;
drop trigger if exists profiles_guard_role on public.profiles;
create trigger profiles_guard_role before insert or update of role on public.profiles
  for each row execute function public.profiles_guard_role();

create or replace function public.staff_demo_site()
returns uuid language plpgsql security definer set search_path to 'public' as $fn$
declare
  uid uuid := (select auth.uid());
  src uuid := 'ad42b098-fa73-4311-bc0d-c1771512a021';  -- « Greg Site 5 » de greg@starvolt.fr
  nid uuid := gen_random_uuid();
  existant uuid;
  p record;
begin
  if uid is null then raise exception 'not_authenticated'; end if;
  select prenom, nom, role into p from public.profiles where id = uid;
  if p.role is distinct from 'staff' then raise exception 'forbidden'; end if;
  -- Idempotent : un staff qui a déjà un site avec des données le garde.
  select id into existant from public.sites
    where user_id = uid and conso_profil is not null order by created_at limit 1;
  if existant is not null then return existant; end if;
  insert into public.sites
  select (jsonb_populate_record(null::public.sites, to_jsonb(s) || jsonb_build_object(
    'id', nid, 'user_id', uid, 'created_at', now(), 'pdl', null,
    'titulaire_prenom', p.prenom, 'titulaire_nom', p.nom,
    'signer_prenom', null, 'signer_nom', null, 'signer_email', null))).*
  from public.sites s where s.id = src;
  if not found then raise exception 'source_site_missing'; end if;
  update public.profiles set active_site_id = nid where id = uid;
  return nid;
end;
$fn$;
revoke execute on function public.staff_demo_site() from anon, public;
grant execute on function public.staff_demo_site() to authenticated;

commit;
