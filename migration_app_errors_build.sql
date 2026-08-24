-- Journal des erreurs : tracer le numéro de build (SHA du commit déployé) sur
-- chaque erreur, pour savoir sur quelle version elle est survenue et filtrer.

alter table public.app_errors add column if not exists build text;

-- log_app_error : nouveau paramètre p_build (en fin, défaut null → appels
-- existants inchangés). On DROP l'ancienne signature pour éviter une surcharge.
drop function if exists public.log_app_error(text,text,text,jsonb,text,text,text);
create function public.log_app_error(
  p_severity   text,
  p_module     text,
  p_message    text,
  p_detail     jsonb default null,
  p_screen     text  default null,
  p_url        text  default null,
  p_user_agent text  default null,
  p_build      text  default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.app_errors(user_id, severity, module, message, detail, screen, url, user_agent, build)
  values (
    auth.uid(),
    case when p_severity in ('bloquant','majeur','mineur') then p_severity else 'majeur' end,
    nullif(p_module, ''),
    left(coalesce(nullif(p_message, ''), '(sans message)'), 2000),
    p_detail,
    nullif(p_screen, ''),
    left(nullif(p_url, ''), 500),
    left(p_user_agent, 400),
    left(nullif(p_build, ''), 80)
  );
end; $$;
grant execute on function public.log_app_error(text,text,text,jsonb,text,text,text,text) to anon, authenticated;

-- get_app_errors : renvoyer aussi build. Changement de type de retour → DROP.
drop function if exists public.get_app_errors(int);
create function public.get_app_errors(p_limit int default 100)
returns table(
  id uuid, created_at timestamptz, severity text, module text, message text,
  detail jsonb, screen text, url text, user_agent text, build text,
  user_id uuid, prenom text, nom text, email text
)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  return query
  select e.id, e.created_at, e.severity, e.module, e.message, e.detail, e.screen, e.url, e.user_agent, e.build,
         e.user_id, p.prenom, p.nom, u.email::text
  from public.app_errors e
  left join public.profiles p on p.id = e.user_id
  left join auth.users u on u.id = e.user_id
  order by e.created_at desc
  limit greatest(1, least(p_limit, 500));
end; $$;
grant execute on function public.get_app_errors(int) to authenticated;
