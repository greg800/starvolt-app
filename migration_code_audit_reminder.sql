-- Rappel « lance l'audit code » : statut du dernier audit code (trigger_type='code').
-- Renvoie la date du dernier audit code et un booléen overdue (> 1 mois ou jamais).
-- Garde admin/superadmin ; utilisé pour le popup de rappel au login.
create or replace function public.get_code_audit_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare last_at timestamptz;
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')) then
    return null;
  end if;
  select max(created_at) into last_at
  from public.security_checks
  where trigger_type = 'code' and status = 'done';
  return jsonb_build_object(
    'last_code_audit', last_at,
    'overdue', (last_at is null or last_at < now() - interval '1 month')
  );
end;
$$;

grant execute on function public.get_code_audit_status() to authenticated;
