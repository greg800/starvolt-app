-- ═══════════════════════════════════════════════════════════════════════════
--  Starvolt — migration_retours : les retours des utilisateurs, repris de l'application
--  Comwatt (migrations 027, 029, 030 de comwatt-app), en lieu et place du
--  mécanisme app_feedback, dont la table et le bucket restent en place
--  pour mémoire mais ne sont plus utilisés par l'écran.
--
--  Un retour (pouce haut / pouce bas) garde l'endroit exact où il a été laissé
--  (l'état de l'écran, le point cliqué), un message, une image, une note audio,
--  une pièce jointe. Sous chaque retour, un fil : l'équipe répond, l'auteur
--  répond à son tour ; chacun modifie ou efface ses propres messages, le
--  administrateur (admin ou superadmin, is_admin) ou l'auteur efface toute la discussion. La lecture d'un fil est
--  datée par personne (retour_lectures) : est non lu tout message d'autrui
--  plus récent. RLS sans policy, tout passe par des RPC security definer.
--  Les fichiers vivent dans le dossier de leur auteur (<uid>/…) du bucket
--  privé `retours`. Rejouable.
-- ═══════════════════════════════════════════════════════════════════════════
set check_function_bodies = off;

create table if not exists public.retours (
  id           uuid primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  modifie_le   timestamptz,
  user_id      uuid not null,
  sentiment    text not null check (sentiment in ('up', 'down')),
  message      text,
  route        text,            -- l'état de l'écran, en JSON (screen, axe, personne…)
  ecran        text,            -- le nom lisible de l'écran
  detail       jsonb,           -- viewport, scroll, build, ua, derniers_clics, cible
  image_path   text,
  audio_path   text,
  fichier_path text,
  fichier_nom  text,
  lu_le        timestamptz,
  lu_par       uuid
);
create index if not exists retours_date_idx    on public.retours (created_at desc);
create index if not exists retours_non_lus_idx on public.retours (created_at desc) where lu_le is null;
alter table public.retours enable row level security;
revoke all on public.retours from anon, authenticated;

create table if not exists public.retour_messages (
  id           uuid primary key default gen_random_uuid(),
  retour_id    uuid not null references public.retours(id) on delete cascade,
  user_id      uuid not null,
  created_at   timestamptz not null default now(),
  modifie_le   timestamptz,
  texte        text,
  image_path   text,
  audio_path   text,
  fichier_path text,
  fichier_nom  text
);
create index if not exists retour_messages_fil_idx on public.retour_messages (retour_id, created_at);
alter table public.retour_messages enable row level security;
revoke all on public.retour_messages from anon, authenticated;

create table if not exists public.retour_lectures (
  retour_id uuid not null references public.retours(id) on delete cascade,
  user_id   uuid not null,
  lu_le     timestamptz not null default now(),
  primary key (retour_id, user_id)
);
alter table public.retour_lectures enable row level security;
revoke all on public.retour_lectures from anon, authenticated;

-- Qui voit un fil : son auteur, ou un administrateur (is_admin : admin ou superadmin).
create or replace function public.retour_acces(p_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (public.is_admin()
         or exists (select 1 from public.retours where id = p_id and user_id = auth.uid()));
$$;
revoke all on function public.retour_acces(uuid) from public, anon;
grant execute on function public.retour_acces(uuid) to authenticated;

-- ── Déposer un retour ───────────────────────────────────────────────────────
create or replace function public.retour_deposer(p jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); n int; rid uuid; img text; aud text; fic text; dos text;
begin
  if uid is null then raise exception 'forbidden'; end if;
  if p is null or jsonb_typeof(p) <> 'object' then raise exception 'retour vide'; end if;
  if coalesce(p->>'sentiment', '') not in ('up', 'down') then raise exception 'sentiment inconnu'; end if;
  select count(*) into n from public.retours where user_id = uid and created_at > now() - interval '1 hour';
  if n >= 30 then raise exception 'trop de retours en une heure'; end if;
  dos := uid::text || '/';
  img := nullif(p->>'image_path', ''); aud := nullif(p->>'audio_path', ''); fic := nullif(p->>'fichier_path', '');
  if img is not null and left(img, length(dos)) <> dos then raise exception 'image hors du dossier'; end if;
  if aud is not null and left(aud, length(dos)) <> dos then raise exception 'audio hors du dossier'; end if;
  if fic is not null and left(fic, length(dos)) <> dos then raise exception 'fichier hors du dossier'; end if;
  if nullif(btrim(coalesce(p->>'message', '')), '') is null and img is null and aud is null and fic is null
     and (p->'detail'->'cible') is null then
    raise exception 'retour vide';
  end if;
  insert into public.retours (user_id, sentiment, message, route, ecran, detail, image_path, audio_path, fichier_path, fichier_nom)
  values (uid, p->>'sentiment', left(nullif(btrim(coalesce(p->>'message', '')), ''), 4000),
          left(p->>'route', 2000), left(p->>'ecran', 120),
          case when jsonb_typeof(p->'detail') = 'object' then p->'detail' end,
          left(img, 300), left(aud, 300), left(fic, 300), left(nullif(p->>'fichier_nom', ''), 200))
  returning id into rid;
  return rid;
end $$;
revoke all on function public.retour_deposer(jsonb) from public, anon;
grant execute on function public.retour_deposer(jsonb) to authenticated;

-- ── Le fil complet, et la lecture datée ─────────────────────────────────────
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
               r.image_path, r.audio_path, r.fichier_path, r.fichier_nom, r.lu_le, p.prenom, p.nom, p.pseudo, p.role,
               case when adm then u.email::text end as email
        from public.retours r
        left join public.profiles p on p.id = r.user_id
        left join auth.users u on u.id = r.user_id
        where r.id = p_id) x),
    'messages', coalesce((select jsonb_agg(to_jsonb(m) order by m.created_at) from (
        select m.id, m.user_id, m.created_at, m.modifie_le, m.texte, m.image_path, m.audio_path, m.fichier_path, m.fichier_nom,
               p.prenom, p.nom, p.pseudo, p.role
        from public.retour_messages m
        left join public.profiles p on p.id = m.user_id
        where m.retour_id = p_id) m), '[]'::jsonb),
    'moi', uid, 'admin', adm) into res;
  return res;
end $$;
revoke all on function public.retour_fil(uuid) from public, anon;
grant execute on function public.retour_fil(uuid) to authenticated;

-- ── Poster, modifier, supprimer un message ──────────────────────────────────
create or replace function public.retour_message_poster(p_retour uuid, p_texte text, p_image text default null, p_audio text default null,
                                                        p_fichier text default null, p_fichier_nom text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); n int; dos text; img text; aud text; fic text; txt text; m public.retour_messages;
begin
  if not public.retour_acces(p_retour) then raise exception 'forbidden'; end if;
  select count(*) into n from public.retour_messages where user_id = uid and created_at > now() - interval '1 hour';
  if n >= 60 then raise exception 'trop de messages en une heure'; end if;
  dos := uid::text || '/';
  img := nullif(p_image, ''); aud := nullif(p_audio, ''); fic := nullif(p_fichier, ''); txt := left(nullif(btrim(coalesce(p_texte, '')), ''), 4000);
  if img is not null and left(img, length(dos)) <> dos then raise exception 'image hors du dossier'; end if;
  if aud is not null and left(aud, length(dos)) <> dos then raise exception 'audio hors du dossier'; end if;
  if fic is not null and left(fic, length(dos)) <> dos then raise exception 'fichier hors du dossier'; end if;
  if txt is null and img is null and aud is null and fic is null then raise exception 'message vide'; end if;
  insert into public.retour_messages (retour_id, user_id, texte, image_path, audio_path, fichier_path, fichier_nom)
  values (p_retour, uid, txt, left(img, 300), left(aud, 300), left(fic, 300), left(nullif(p_fichier_nom, ''), 200)) returning * into m;
  insert into public.retour_lectures (retour_id, user_id, lu_le) values (p_retour, uid, now())
  on conflict (retour_id, user_id) do update set lu_le = now();
  return to_jsonb(m);
end $$;
revoke all on function public.retour_message_poster(uuid, text, text, text, text, text) from public, anon;
grant execute on function public.retour_message_poster(uuid, text, text, text, text, text) to authenticated;

create or replace function public.retour_message_modifier(p_id uuid, p_texte text, p_image text default null, p_audio text default null,
                                                          p_fichier text default null, p_fichier_nom text default null)
returns void language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); dos text; img text; aud text; fic text; txt text;
begin
  if uid is null then raise exception 'forbidden'; end if;
  dos := uid::text || '/';
  img := nullif(p_image, ''); aud := nullif(p_audio, ''); fic := nullif(p_fichier, ''); txt := left(nullif(btrim(coalesce(p_texte, '')), ''), 4000);
  if img is not null and left(img, length(dos)) <> dos then raise exception 'image hors du dossier'; end if;
  if aud is not null and left(aud, length(dos)) <> dos then raise exception 'audio hors du dossier'; end if;
  if fic is not null and left(fic, length(dos)) <> dos then raise exception 'fichier hors du dossier'; end if;
  if txt is null and img is null and aud is null and fic is null then raise exception 'message vide'; end if;
  update public.retour_messages set texte = txt, image_path = left(img, 300), audio_path = left(aud, 300),
         fichier_path = left(fic, 300), fichier_nom = left(nullif(p_fichier_nom, ''), 200), modifie_le = now()
  where id = p_id and user_id = uid;
  if not found then raise exception 'forbidden'; end if;
end $$;
revoke all on function public.retour_message_modifier(uuid, text, text, text, text, text) from public, anon;
grant execute on function public.retour_message_modifier(uuid, text, text, text, text, text) to authenticated;

create or replace function public.retour_message_supprimer(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from public.retour_messages where id = p_id and user_id = auth.uid();
  if not found then raise exception 'forbidden'; end if;
end $$;
revoke all on function public.retour_message_supprimer(uuid) from public, anon;
grant execute on function public.retour_message_supprimer(uuid) to authenticated;

create or replace function public.retour_modifier(p_id uuid, p_texte text)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.retours set message = left(nullif(btrim(coalesce(p_texte, '')), ''), 4000), modifie_le = now()
  where id = p_id and user_id = auth.uid();
  if not found then raise exception 'forbidden'; end if;
end $$;
revoke all on function public.retour_modifier(uuid, text) from public, anon;
grant execute on function public.retour_modifier(uuid, text) to authenticated;

create or replace function public.retour_supprimer(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.retour_acces(p_id) then raise exception 'forbidden'; end if;
  delete from public.retours where id = p_id;
end $$;
revoke all on function public.retour_supprimer(uuid) from public, anon;
grant execute on function public.retour_supprimer(uuid) to authenticated;

create or replace function public.retour_marquer_lu(p_id uuid, p_lu boolean default true)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  if p_id is null then
    update public.retours set lu_le = now(), lu_par = auth.uid() where lu_le is null;
  else
    update public.retours set lu_le = case when p_lu then now() end, lu_par = case when p_lu then auth.uid() end
    where id = p_id;
  end if;
end $$;
revoke all on function public.retour_marquer_lu(uuid, boolean) from public, anon;
grant execute on function public.retour_marquer_lu(uuid, boolean) to authenticated;

-- ── Les listes ──────────────────────────────────────────────────────────────
drop function if exists public.retours_miens();
create or replace function public.retours_miens()
returns table (id uuid, created_at timestamptz, sentiment text, message text, route text, ecran text,
               image_path text, audio_path text, fichier_path text, cible boolean,
               n_messages bigint, dernier_le timestamptz, nouveaux bigint)
language sql stable security definer set search_path = public as $$
  select r.id, r.created_at, r.sentiment, r.message, r.route, r.ecran, r.image_path, r.audio_path, r.fichier_path,
         (r.detail->'cible') is not null,
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
               lu_le timestamptz, prenom text, nom text, pseudo text, email text,
               n_messages bigint, dernier_le timestamptz, nouveaux bigint)
language sql stable security definer set search_path = public as $$
  select r.id, r.created_at, r.user_id, r.sentiment, r.message, r.route, r.ecran, r.detail,
         r.image_path, r.audio_path, r.fichier_path, r.lu_le, p.prenom, p.nom, p.pseudo, u.email::text,
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

-- ── Les pastilles et les pop-ups ────────────────────────────────────────────
create or replace function public.retours_non_lus()
returns jsonb language sql stable security definer set search_path = public as $$
  with nouveaux as (
    select m.retour_id, max(m.created_at) as dernier
    from public.retour_messages m
    left join public.retour_lectures l on l.retour_id = m.retour_id and l.user_id = auth.uid()
    where m.user_id <> auth.uid() and m.created_at > coalesce(l.lu_le, '-infinity')
    group by m.retour_id),
  derniers as (
    select nv.retour_id, nv.dernier, m.user_id, left(m.texte, 120) as texte,
           m.image_path is not null as image, m.audio_path is not null as audio
    from nouveaux nv
    join public.retour_messages m on m.retour_id = nv.retour_id and m.created_at = nv.dernier),
  evenements as (
    select r.id, 'retour'::text as type, r.created_at as quand, r.sentiment, r.ecran, left(r.message, 120) as message,
           r.user_id as auteur, r.image_path is not null as image, r.audio_path is not null as audio
    from public.retours r where public.is_admin() and r.lu_le is null
    union all
    select r.id, 'message', d.dernier, r.sentiment, r.ecran, d.texte, d.user_id, d.image, d.audio
    from derniers d join public.retours r on r.id = d.retour_id
    where public.is_admin() and r.user_id <> auth.uid()),
  reponses as (
    select r.id, d.dernier as quand, r.sentiment, r.ecran, d.texte as message, d.user_id as auteur, d.image, d.audio
    from derniers d join public.retours r on r.id = d.retour_id
    where r.user_id = auth.uid())
  select jsonb_build_object(
    'n', (select count(distinct id) from evenements),
    'dernier', (select jsonb_build_object('id', e.id, 'type', e.type, 'sentiment', e.sentiment, 'ecran', e.ecran,
                                         'message', e.message, 'prenom', p.prenom, 'nom', p.nom, 'pseudo', p.pseudo,
                                         'created_at', e.quand, 'image', e.image, 'audio', e.audio)
                from evenements e left join public.profiles p on p.id = e.auteur
                order by e.quand desc limit 1),
    'reponses', (select count(*) from reponses),
    'derniere', (select jsonb_build_object('id', e.id, 'sentiment', e.sentiment, 'ecran', e.ecran,
                                          'message', e.message, 'prenom', p.prenom, 'nom', p.nom, 'pseudo', p.pseudo,
                                          'created_at', e.quand, 'image', e.image, 'audio', e.audio)
                 from reponses e left join public.profiles p on p.id = e.auteur
                 order by e.quand desc limit 1));
$$;
revoke all on function public.retours_non_lus() from public, anon;
grant execute on function public.retours_non_lus() to authenticated;

-- Un compte supprimé emporte ses retours, ses messages et ses lectures.
create or replace function public.retours_purge_compte()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  delete from public.retours where user_id = old.id;
  delete from public.retour_messages where user_id = old.id;
  delete from public.retour_lectures where user_id = old.id;
  return old;
end $$;
drop trigger if exists retours_purge_compte on auth.users;
create trigger retours_purge_compte after delete on auth.users
  for each row execute function public.retours_purge_compte();
revoke all on function public.retours_purge_compte() from public, anon, authenticated;

-- ── Le bucket `retours` : privé, 20 Mo, images, audio, PDF et bureautique ───
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('retours', 'retours', false, 20971520, array[
    'image/png', 'image/jpeg', 'image/webp', 'image/gif',
    'audio/webm', 'audio/mp4', 'audio/ogg', 'audio/mpeg', 'audio/wav', 'audio/aac', 'audio/x-m4a',
    'application/pdf', 'text/plain', 'text/csv', 'text/markdown',
    'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.oasis.opendocument.text', 'application/vnd.oasis.opendocument.spreadsheet',
    'application/vnd.oasis.opendocument.presentation', 'application/rtf'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit,
                               allowed_mime_types = excluded.allowed_mime_types;

-- Qui lit un fichier : un administrateur, son propre dossier, ou un fichier d'un message de l'un de ses fils.
create or replace function public.retour_fichier_visible(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (
    public.is_admin()
    or split_part(p_name, '/', 1) = auth.uid()::text
    or exists (select 1 from public.retour_messages m join public.retours r on r.id = m.retour_id
               where r.user_id = auth.uid() and (m.image_path = p_name or m.audio_path = p_name or m.fichier_path = p_name)));
$$;
revoke all on function public.retour_fichier_visible(text) from public, anon;
grant execute on function public.retour_fichier_visible(text) to authenticated;

drop policy if exists "retours depot"       on storage.objects;
drop policy if exists "retours lecture"     on storage.objects;
drop policy if exists "retours suppression" on storage.objects;
create policy "retours depot" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'retours' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "retours lecture" on storage.objects
  for select to authenticated
  using (bucket_id = 'retours' and public.retour_fichier_visible(name));
create policy "retours suppression" on storage.objects
  for delete to authenticated
  using (bucket_id = 'retours' and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text));
