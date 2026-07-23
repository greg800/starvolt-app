-- Fichiers de données métier (Markdown) attachés aux prompts IA, éditables depuis
-- l'admin « Prompts IA ». Remplace le fichier statique bilan-dpe-reference.md :
-- désormais la source de vérité est en base (édition immédiate, sans redéploiement),
-- lue par les edge functions via service_role et par l'admin via RPC.

create table if not exists public.ai_prompt_files (
  id         uuid primary key default gen_random_uuid(),
  feature    text not null,                 -- prompt auquel le fichier est rattaché (ai_prompts.feature)
  label      text not null,                 -- nom lisible affiché dans l'admin
  content    text not null default '',      -- contenu Markdown
  updated_at timestamptz not null default now(),
  updated_by text,
  created_at timestamptz not null default now()
);
create index if not exists ai_prompt_files_feature_idx on public.ai_prompt_files(feature);

alter table public.ai_prompt_files enable row level security;
-- Pas de policy : écriture/lecture edge via service_role (bypass) ; admin via RPC SECURITY DEFINER.

-- Lecture (UI admin ; sans garde interne, comme get_ai_prompts — repose sur l'UI admin)
create or replace function public.get_prompt_files()
returns setof public.ai_prompt_files
language sql security definer set search_path = public as $$
  select * from public.ai_prompt_files order by feature, created_at;
$$;
grant execute on function public.get_prompt_files() to authenticated;

-- Mise à jour (garde admin : seul greg@starvolt.fr)
create or replace function public.set_prompt_file(p_id uuid, p_label text, p_content text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.jwt()->>'email' <> 'greg@starvolt.fr' then raise exception 'forbidden'; end if;
  update public.ai_prompt_files
     set label      = coalesce(nullif(p_label,''), label),
         content    = coalesce(p_content, content),
         updated_at = now(),
         updated_by = auth.jwt()->>'email'
   where id = p_id;
end; $$;
grant execute on function public.set_prompt_file(uuid, text, text) to authenticated;

-- Création d'un nouveau fichier attaché à un prompt (garde admin)
create or replace function public.create_prompt_file(p_feature text, p_label text, p_content text default '')
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.jwt()->>'email' <> 'greg@starvolt.fr' then raise exception 'forbidden'; end if;
  insert into public.ai_prompt_files(feature, label, content, updated_by)
    values (p_feature, coalesce(nullif(p_label,''), 'Nouveau fichier'), coalesce(p_content,''), auth.jwt()->>'email')
    returning id into v_id;
  return v_id;
end; $$;
grant execute on function public.create_prompt_file(text, text, text) to authenticated;

-- Suppression (garde admin)
create or replace function public.delete_prompt_file(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.jwt()->>'email' <> 'greg@starvolt.fr' then raise exception 'forbidden'; end if;
  delete from public.ai_prompt_files where id = p_id;
end; $$;
grant execute on function public.delete_prompt_file(uuid) to authenticated;
