-- Journal des erreurs applicatives, affiché en haut de la page Cyber-sécurité.
-- Capture les erreurs JS non gérées + les échecs d'appels (edge functions, etc.)
-- avec le contexte maximal, pour pouvoir demander un correctif à Claude.

create table if not exists public.app_errors (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  user_id     uuid references auth.users(id) on delete set null,
  severity    text not null default 'majeur',   -- bloquant | majeur | mineur
  module      text,                             -- module / écran générateur
  message     text not null,
  detail      jsonb,                            -- contexte max (status, payload, stack…)
  screen      text,
  url         text,
  user_agent  text
);
create index if not exists app_errors_created_idx on public.app_errors (created_at desc);

alter table public.app_errors enable row level security;
-- Aucune policy : tout passe par les RPC security-definer ci-dessous.

-- Écriture : ouverte (anon + authenticated) car une erreur peut survenir avant
-- connexion. Le rôle appelant ne choisit pas le user_id (pris de auth.uid()).
create or replace function public.log_app_error(
  p_severity   text,
  p_module     text,
  p_message    text,
  p_detail     jsonb default null,
  p_screen     text  default null,
  p_url        text  default null,
  p_user_agent text  default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.app_errors(user_id, severity, module, message, detail, screen, url, user_agent)
  values (
    auth.uid(),
    case when p_severity in ('bloquant','majeur','mineur') then p_severity else 'majeur' end,
    nullif(p_module, ''),
    left(coalesce(nullif(p_message, ''), '(sans message)'), 2000),
    p_detail,
    nullif(p_screen, ''),
    left(nullif(p_url, ''), 500),
    left(p_user_agent, 400)
  );
end; $$;
grant execute on function public.log_app_error(text,text,text,jsonb,text,text,text) to anon, authenticated;

-- Lecture : admin uniquement, jointe au profil pour nommer la personne.
create or replace function public.get_app_errors(p_limit int default 100)
returns table(
  id uuid, created_at timestamptz, severity text, module text, message text,
  detail jsonb, screen text, url text, user_agent text,
  user_id uuid, prenom text, nom text, email text
)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  return query
  select e.id, e.created_at, e.severity, e.module, e.message, e.detail, e.screen, e.url, e.user_agent,
         e.user_id, p.prenom, p.nom, u.email::text
  from public.app_errors e
  left join public.profiles p on p.id = e.user_id
  left join auth.users u on u.id = e.user_id
  order by e.created_at desc
  limit greatest(1, least(p_limit, 500));
end; $$;
grant execute on function public.get_app_errors(int) to authenticated;

-- Purge : admin uniquement. p_id nul = tout vider.
create or replace function public.clear_app_errors(p_id uuid default null)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if p_id is null then delete from public.app_errors;
  else delete from public.app_errors where id = p_id;
  end if;
end; $$;
grant execute on function public.clear_app_errors(uuid) to authenticated;
