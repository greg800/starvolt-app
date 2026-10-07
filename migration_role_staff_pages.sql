-- Rôle « staff » : accès en consultation à certaines pages admin (prix spot,
-- tarifs d'électricité), cochées dans app_roles.permissions.admin_pages depuis
-- l'écran Gestion des rôles. Les écritures restent réservées à is_admin().
begin;

create or replace function public.has_admin_page(p_page text)
returns boolean language sql stable security definer set search_path to 'public' as $fn$
  select public.is_admin() or exists (
    select 1 from public.profiles p
    join public.app_roles r on r.key = p.role
    where p.id = (select auth.uid())
      and (r.permissions -> 'admin_pages' ->> p_page) = 'true'
  );
$fn$;
revoke execute on function public.has_admin_page(text) from anon, public;
grant execute on function public.has_admin_page(text) to authenticated;

-- Seule table lue par la page Prix spot qui était fermée aux non-admins.
drop policy if exists staff_read on public.spot_batterie_params;
create policy staff_read on public.spot_batterie_params
  for select to authenticated using ((select public.has_admin_page('prix_spot')));

commit;
