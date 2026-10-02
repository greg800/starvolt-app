-- ═══════════════════════════════════════════════════════════════════════════
--  Starvolt — migration_retours_plusieurs_images : plusieurs images par retour et par message (repris de
--  Comwatt 032, 2026-10-02). `images text[]` (dix au plus) ; `image_path` reste
--  la première pour les listes, les pop-ups et les anciennes lignes. Rejouable.
-- ═══════════════════════════════════════════════════════════════════════════
set check_function_bodies = off;

alter table public.retours         add column if not exists images text[];
alter table public.retour_messages add column if not exists images text[];

create or replace function public.retour_images_valides(p_images text[], p_image text, p_dos text)
returns text[] language plpgsql immutable as $$
declare res text[] := '{}'; c text;
begin
  foreach c in array coalesce(p_images, case when nullif(p_image, '') is not null then array[p_image] else '{}'::text[] end) loop
    c := nullif(btrim(coalesce(c, '')), '');
    if c is null or c = any(res) then continue; end if;
    if left(c, length(p_dos)) <> p_dos then raise exception 'image hors du dossier'; end if;
    res := res || left(c, 300);
  end loop;
  if cardinality(res) > 10 then raise exception 'dix images au plus'; end if;
  return nullif(res, '{}');
end $$;

create or replace function public.retour_deposer(p jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); n int; rid uuid; imgs text[]; aud text; fic text; dos text;
begin
  if uid is null then raise exception 'forbidden'; end if;
  if p is null or jsonb_typeof(p) <> 'object' then raise exception 'retour vide'; end if;
  if coalesce(p->>'sentiment', '') not in ('up', 'down') then raise exception 'sentiment inconnu'; end if;
  select count(*) into n from public.retours where user_id = uid and created_at > now() - interval '1 hour';
  if n >= 30 then raise exception 'trop de retours en une heure'; end if;
  dos := uid::text || '/';
  imgs := public.retour_images_valides(
            case when jsonb_typeof(p->'images') = 'array' then array(select jsonb_array_elements_text(p->'images')) end,
            p->>'image_path', dos);
  aud := nullif(p->>'audio_path', ''); fic := nullif(p->>'fichier_path', '');
  if aud is not null and left(aud, length(dos)) <> dos then raise exception 'audio hors du dossier'; end if;
  if fic is not null and left(fic, length(dos)) <> dos then raise exception 'fichier hors du dossier'; end if;
  if nullif(btrim(coalesce(p->>'message', '')), '') is null and imgs is null and aud is null and fic is null
     and (p->'detail'->'cible') is null then
    raise exception 'retour vide';
  end if;
  insert into public.retours (user_id, sentiment, message, route, ecran, detail, image_path, images, audio_path, fichier_path, fichier_nom)
  values (uid, p->>'sentiment', left(nullif(btrim(coalesce(p->>'message', '')), ''), 4000),
          left(p->>'route', 2000), left(p->>'ecran', 120),
          case when jsonb_typeof(p->'detail') = 'object' then p->'detail' end,
          imgs[1], imgs, left(aud, 300), left(fic, 300), left(nullif(p->>'fichier_nom', ''), 200))
  returning id into rid;
  return rid;
end $$;

drop function if exists public.retour_message_poster(uuid, text, text, text, text, text);
create or replace function public.retour_message_poster(p_retour uuid, p_texte text, p_image text default null, p_audio text default null,
                                                        p_fichier text default null, p_fichier_nom text default null, p_images text[] default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); n int; dos text; imgs text[]; aud text; fic text; txt text; m public.retour_messages;
begin
  if not public.retour_acces(p_retour) then raise exception 'forbidden'; end if;
  select count(*) into n from public.retour_messages where user_id = uid and created_at > now() - interval '1 hour';
  if n >= 60 then raise exception 'trop de messages en une heure'; end if;
  dos := uid::text || '/';
  imgs := public.retour_images_valides(p_images, p_image, dos);
  aud := nullif(p_audio, ''); fic := nullif(p_fichier, ''); txt := left(nullif(btrim(coalesce(p_texte, '')), ''), 4000);
  if aud is not null and left(aud, length(dos)) <> dos then raise exception 'audio hors du dossier'; end if;
  if fic is not null and left(fic, length(dos)) <> dos then raise exception 'fichier hors du dossier'; end if;
  if txt is null and imgs is null and aud is null and fic is null then raise exception 'message vide'; end if;
  insert into public.retour_messages (retour_id, user_id, texte, image_path, images, audio_path, fichier_path, fichier_nom)
  values (p_retour, uid, txt, imgs[1], imgs, left(aud, 300), left(fic, 300), left(nullif(p_fichier_nom, ''), 200)) returning * into m;
  insert into public.retour_lectures (retour_id, user_id, lu_le) values (p_retour, uid, now())
  on conflict (retour_id, user_id) do update set lu_le = now();
  return to_jsonb(m);
end $$;
revoke all on function public.retour_message_poster(uuid, text, text, text, text, text, text[]) from public, anon;
grant execute on function public.retour_message_poster(uuid, text, text, text, text, text, text[]) to authenticated;

drop function if exists public.retour_message_modifier(uuid, text, text, text, text, text);
create or replace function public.retour_message_modifier(p_id uuid, p_texte text, p_image text default null, p_audio text default null,
                                                          p_fichier text default null, p_fichier_nom text default null, p_images text[] default null)
returns void language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); dos text; imgs text[]; aud text; fic text; txt text;
begin
  if uid is null then raise exception 'forbidden'; end if;
  dos := uid::text || '/';
  imgs := public.retour_images_valides(p_images, p_image, dos);
  aud := nullif(p_audio, ''); fic := nullif(p_fichier, ''); txt := left(nullif(btrim(coalesce(p_texte, '')), ''), 4000);
  if aud is not null and left(aud, length(dos)) <> dos then raise exception 'audio hors du dossier'; end if;
  if fic is not null and left(fic, length(dos)) <> dos then raise exception 'fichier hors du dossier'; end if;
  if txt is null and imgs is null and aud is null and fic is null then raise exception 'message vide'; end if;
  update public.retour_messages set texte = txt, image_path = imgs[1], images = imgs, audio_path = left(aud, 300),
         fichier_path = left(fic, 300), fichier_nom = left(nullif(p_fichier_nom, ''), 200), modifie_le = now()
  where id = p_id and user_id = uid;
  if not found then raise exception 'forbidden'; end if;
end $$;
revoke all on function public.retour_message_modifier(uuid, text, text, text, text, text, text[]) from public, anon;
grant execute on function public.retour_message_modifier(uuid, text, text, text, text, text, text[]) to authenticated;

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
               r.image_path, r.images, r.audio_path, r.fichier_path, r.fichier_nom, r.lu_le, r.statut, r.statut_le,
               p.prenom, p.nom, p.pseudo, p.role,
               case when adm then u.email::text end as email
        from public.retours r
        left join public.profiles p on p.id = r.user_id
        left join auth.users u on u.id = r.user_id
        where r.id = p_id) x),
    'messages', coalesce((select jsonb_agg(to_jsonb(m) order by m.created_at) from (
        select m.id, m.user_id, m.created_at, m.modifie_le, m.texte, m.image_path, m.images, m.audio_path, m.fichier_path, m.fichier_nom,
               m.classement, p.prenom, p.nom, p.pseudo, p.role
        from public.retour_messages m
        left join public.profiles p on p.id = m.user_id
        where m.retour_id = p_id) m), '[]'::jsonb),
    'moi', uid, 'admin', adm) into res;
  return res;
end $$;

create or replace function public.retour_fichier_visible(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (
    public.is_admin()
    or split_part(p_name, '/', 1) = auth.uid()::text
    or exists (select 1 from public.retour_messages m join public.retours r on r.id = m.retour_id
               where r.user_id = auth.uid()
                 and (m.image_path = p_name or m.audio_path = p_name or m.fichier_path = p_name or p_name = any(m.images))));
$$;
