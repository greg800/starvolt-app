-- « Vider » le journal des erreurs échouait avec « DELETE requires a WHERE
-- clause » (code 21000) : les connexions PostgREST de Supabase chargent
-- l'extension safeupdate, qui rejette tout DELETE sans WHERE, même à
-- l'intérieur d'une fonction SECURITY DEFINER. La suppression totale porte
-- désormais une clause WHERE toujours vraie. Le comportement par ligne
-- (p_id fourni) est inchangé.
create or replace function public.clear_app_errors(p_id uuid default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if p_id is null then
    delete from public.app_errors where created_at <= now();
  else
    delete from public.app_errors where id = p_id;
  end if;
end; $$;

revoke execute on function public.clear_app_errors(uuid) from anon, public;
grant  execute on function public.clear_app_errors(uuid) to authenticated;
