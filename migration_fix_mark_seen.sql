-- Re-déploiement défensif de mark_security_check_seen.
-- Symptôme : le popup du dernier audit réapparaît à chaque login malgré « J'ai compris ».
-- Cause probable : seen_by n'est jamais mis à jour (fonction absente/erronée en prod,
-- ou l'appel RPC échoue silencieusement côté client). create or replace garantit
-- une définition correcte et idempotente.
create or replace function public.mark_security_check_seen(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')) then
    raise exception 'forbidden';
  end if;
  update public.security_checks
  set seen_by = case when seen_by ? auth.uid()::text then seen_by
                     else coalesce(seen_by, '[]'::jsonb) || to_jsonb(auth.uid()::text) end
  where id = p_id;
end;
$$;

grant execute on function public.mark_security_check_seen(uuid) to authenticated;
