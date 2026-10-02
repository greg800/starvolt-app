-- ═══════════════════════════════════════════════════════════════════════════
--  Starvolt — migration_retours_classement : classer un retour, avec une réponse automatique
--  (repris de Comwatt 031, 2026-10-02). L'administrateur (is_admin) classe un
--  retour — a_corriger, corrige, a_analyser — ; le statut vit sur le retour,
--  et la réponse toute faite part dans le fil comme un message ordinaire,
--  marqué `classement`. Rejouable.
-- ═══════════════════════════════════════════════════════════════════════════
set check_function_bodies = off;

alter table public.retours add column if not exists statut     text
  check (statut in ('a_corriger', 'corrige', 'a_analyser'));
alter table public.retours add column if not exists statut_le  timestamptz;
alter table public.retours add column if not exists statut_par uuid;
alter table public.retour_messages add column if not exists classement text
  check (classement in ('a_corriger', 'corrige', 'a_analyser'));

create or replace function public.retour_classement_texte(p_statut text)
returns text language sql immutable as $$
  select case p_statut
    when 'a_corriger' then 'Ok, ça va être corrigé.'
    when 'corrige'    then 'Ok, c''est corrigé, vérifie maintenant.'
    when 'a_analyser' then 'Merci, je vais analyser ton message.'
  end;
$$;
revoke all on function public.retour_classement_texte(text) from public, anon;
grant execute on function public.retour_classement_texte(text) to authenticated;

create or replace function public.retour_classer(p_id uuid, p_statut text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); txt text; m public.retour_messages;
begin
  if uid is null or not public.is_admin() then raise exception 'forbidden'; end if;
  txt := public.retour_classement_texte(p_statut);
  if txt is null then raise exception 'classement inconnu'; end if;
  update public.retours set statut = p_statut, statut_le = now(), statut_par = uid,
         lu_le = coalesce(lu_le, now()), lu_par = coalesce(lu_par, uid)
  where id = p_id;
  if not found then raise exception 'forbidden'; end if;
  insert into public.retour_messages (retour_id, user_id, texte, classement)
  values (p_id, uid, txt, p_statut) returning * into m;
  insert into public.retour_lectures (retour_id, user_id, lu_le) values (p_id, uid, now())
  on conflict (retour_id, user_id) do update set lu_le = now();
  return to_jsonb(m);
end $$;
revoke all on function public.retour_classer(uuid, text) from public, anon;
grant execute on function public.retour_classer(uuid, text) to authenticated;

create or replace function public.retour_fil(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); adm boolean := public.is_admin(); res jsonb;
begin
  if not public.retour_acces(p_id) then raise exception 'forbidden'; end if;
  insert into public.retour_lectures (retour_id, user_id, lu_le) values (p_id, uid, now())
  on conflict (retour_id, user_id) do update set lu_le = now();
  if adm then update public.retours set lu_le = now(), lu_par = uid where id = p_id and lu_le is null; end if;
  select jsonb_build_object(
    'retour', (select to_jsonb(x) from (
        select r.id, r.created_at, r.modifie_le, r.user_id, r.sentiment, r.message, r.route, r.ecran, r.detail,
               r.image_path, r.audio_path, r.fichier_path, r.fichier_nom, r.lu_le, r.statut, r.statut_le,
               p.prenom, p.nom, p.pseudo, p.role,
               case when adm then u.email::text end as email
        from public.retours r
        left join public.profiles p on p.id = r.user_id
        left join auth.users u on u.id = r.user_id
        where r.id = p_id) x),
    'messages', coalesce((select jsonb_agg(to_jsonb(m) order by m.created_at) from (
        select m.id, m.user_id, m.created_at, m.modifie_le, m.texte, m.image_path, m.audio_path, m.fichier_path, m.fichier_nom,
               m.classement, p.prenom, p.nom, p.pseudo, p.role
        from public.retour_messages m
        left join public.profiles p on p.id = m.user_id
        where m.retour_id = p_id) m), '[]'::jsonb),
    'moi', uid, 'admin', adm) into res;
  return res;
end $$;

drop function if exists public.retours_miens();
create or replace function public.retours_miens()
returns table (id uuid, created_at timestamptz, sentiment text, message text, route text, ecran text,
               image_path text, audio_path text, fichier_path text, cible boolean, statut text,
               n_messages bigint, dernier_le timestamptz, nouveaux bigint)
language sql stable security definer set search_path = public as $$
  select r.id, r.created_at, r.sentiment, r.message, r.route, r.ecran, r.image_path, r.audio_path, r.fichier_path,
         (r.detail->'cible') is not null, r.statut,
         (select count(*) from public.retour_messages m where m.retour_id = r.id),
         (select max(m.created_at) from public.retour_messages m where m.retour_id = r.id),
         (select count(*) from public.retour_messages m
           left join public.retour_lectures l on l.retour_id = r.id and l.user_id = auth.uid()
           where m.retour_id = r.id and m.user_id <> auth.uid() and m.created_at > coalesce(l.lu_le, '-infinity'))
  from public.retours r
  where r.user_id = auth.uid()
  order by greatest(r.created_at, coalesce((select max(m.created_at) from public.retour_messages m where m.retour_id = r.id), r.created_at)) desc;
$$;
revoke all on function public.retours_miens() from public, anon;
grant execute on function public.retours_miens() to authenticated;

drop function if exists public.retours_lister(int);
create or replace function public.retours_lister(p_limit int default 200)
returns table (id uuid, created_at timestamptz, user_id uuid, sentiment text, message text,
               route text, ecran text, detail jsonb, image_path text, audio_path text, fichier_path text,
               lu_le timestamptz, statut text, prenom text, nom text, pseudo text, email text,
               n_messages bigint, dernier_le timestamptz, nouveaux bigint)
language sql stable security definer set search_path = public as $$
  select r.id, r.created_at, r.user_id, r.sentiment, r.message, r.route, r.ecran, r.detail,
         r.image_path, r.audio_path, r.fichier_path, r.lu_le, r.statut, p.prenom, p.nom, p.pseudo, u.email::text,
         (select count(*) from public.retour_messages m where m.retour_id = r.id),
         (select max(m.created_at) from public.retour_messages m where m.retour_id = r.id),
         (select count(*) from public.retour_messages m
           left join public.retour_lectures l on l.retour_id = r.id and l.user_id = auth.uid()
           where m.retour_id = r.id and m.user_id <> auth.uid() and m.created_at > coalesce(l.lu_le, '-infinity'))
  from public.retours r
  left join public.profiles p on p.id = r.user_id
  left join auth.users u on u.id = r.user_id
  where public.is_admin()
  order by greatest(r.created_at, coalesce((select max(m.created_at) from public.retour_messages m where m.retour_id = r.id), r.created_at)) desc
  limit greatest(1, least(p_limit, 1000));
$$;
revoke all on function public.retours_lister(int) from public, anon;
grant execute on function public.retours_lister(int) to authenticated;
